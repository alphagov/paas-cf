#!/usr/bin/env python
"""Pipecleaner is a tool for validating concourse pipelines.

It can check for the following issues:

* Resources being used in a job that have not been defined in the
  `resources:` block. (Fatal)
* Resources that have been defined in the `resources:` block and are not
  used in the pipeline. (Warning)
* Resources being used in an `input:` block that have not been
  `get:`-ted. (Fatal)
* Resources that have been `get:`-ted and are not used in the job.
  (Warning)
* `output:`s that are not used later in the job. (Warning)
* Scriptlets that fail the tests implemented by `shellcheck`
  http://www.shellcheck.net/ (Fatal)

By default it will exit with a nonzero exit code for any Fatal errors,
and will exit with a nonzero code for Warnings if you pass the
`--fatal-warnings` flag.

If some checks are not desired (e.g. unused outputs) they can be disabled
with the `--ignore-types` flag.

"""

import yaml
import re
import sys
import os
import getopt
import subprocess


class Pipecleaner(object):
    def __init__(self, ignore_types=[]):
        self.ignore_types = ignore_types

    def validate(self, filename):
        data = self.load_pipeline(filename)
        return self.check_pipeline(data)

    def load_pipeline(self, filename):
        raw = open(filename).read()
        # Regexp taken from https://github.com/cloudfoundry/bosh-cli/blob/21639e8/director/template/template.go#L90
        # (Fly uses bosh-cli's template package to do the interpolation.
        #
        # Include $(date) in the replacement so that shellcheck doesn't assume these substitutions have safe contents
        raw = re.sub('\(\((!?[-/\.\w\pL]+)\)\)', 'DUMMY-$(date)', raw)
        return yaml.load(raw)

    def call_shellcheck(self, shell, args, variables):
        """"Returns the exitcode and any output from running shellcheck"""
        if "shellcheck" in self.ignore_types:
            return 0, ""

        script = ""

        for switch in args[:-1]:
            if switch != "-c":
                script += "set " + switch + "\n"

        for name, value in variables.iteritems():
            # Include $(date) so that shellcheck doesn't assume these variables have safe contents
            script += name + "=\"DUMMY-$(date)\"\n"
            script += "export " + name + "\n"

        script += args[-1]

        process = subprocess.Popen(["shellcheck", "-s", shell, "-"],
                                   stdin=subprocess.PIPE,
                                   stdout=subprocess.PIPE,
                                   stderr=subprocess.STDOUT)
        output = process.communicate(script)[0]
        exitcode = process.returncode

        return exitcode, output

    def check_pipeline(self, data):
        errors = {
            'unknown_resource': [],
            'unfetched_resource': [],
            'unused_fetch': [],
            'unused_resource': [],
            'unused_output': [],
            'shellcheck': [],
        }

        defined_resource_names = set([e['name'] for e in data['resources']])
        overall_used_resources = set()

        for job in data['jobs']:
            plan = job['plan']

            get_resources = set()
            used_resources = set()
            output_resources = set()
            triggered_resources = set()

            while plan:
                item = plan.pop(0)
                discovered_blocks = []

                # Flatten array blocks as we don't care
                for block_type in ('aggregate', 'in_parallel', 'do'):
                    if block_type in item:
                        discovered_blocks.extend(item[block_type])
                        del item[block_type]

                # Flatten single blocks we don't care about
                for block_type in ('on_success', 'on_failure', 'ensure', 'try'):
                    if block_type in item:
                        discovered_blocks.append(item[block_type])
                        del item[block_type]

                if discovered_blocks:
                    plan = [item] + discovered_blocks + plan
                    continue

                if 'get' in item:
                    get_resources.add(item['get'])
                    if 'trigger' in item:
                        triggered_resources.add(item['get'])

                    # `get:` referring to a resource that has not been defined
                    # in `resources:`
                    if item['get'] not in defined_resource_names:
                        errors['unknown_resource'].append({
                            'job': job['name'],
                            'resource': item['get'],
                            'fatal': True
                        })

                # A 'put' also registers the resource as fetched
                if 'put' in item:
                    output_resources.add(item['put'])
                    used_resources.add(item['put'])

                    # It is a common pattern to define an output that is then
                    # used in an ensure block that does not need explicit
                    # inputs
                    if 'params' in item and 'file' in item['params']:
                        directory = os.path.split(item['params']['file'])[0]
                        used_resources.add(directory)

                    # `put:` referring to a resource that has not been defined
                    # in `resources:`
                    if item['put'] not in defined_resource_names:
                        errors['unknown_resource'].append({
                            'job': job['name'],
                            'resource': item['put'],
                            'fatal': True
                        })

                if 'task' in item:
                    if 'file' in item:
                        item['config'] = self.load_pipeline(item['file'])

                    if 'inputs' in item['config']:
                        for i in item['config']['inputs']:
                            used_resources.add(i['name'])

                            # Resources listed as an `input:` to a task that
                            # have not been `get:` or `put:` in this job
                            if i['name'] not in get_resources.union(output_resources):
                                errors['unfetched_resource'].append({
                                    'job': job['name'],
                                    'resource': i['name'],
                                    'task': item['task'],
                                    'fatal': True
                                })

                    if 'outputs' in item['config']:
                        for i in item['config']['outputs']:
                            output_resources.add(i['name'])

                    if 'run' in item['config']:
                        # This list of dialects may expand over time if/when
                        # shellcheck expands its set of dialects.
                        shellcheck_dialects =  ['sh', 'bash', 'dash', 'ksh']
                        if item['config']['run']['path'] in shellcheck_dialects:
                            params = item['config'].get('params', {}) or {}
                            item_params = item.get('params', {}) or {}
                            combined_params = params.copy()
                            combined_params.update(item_params)
                            exitcode, output = self.call_shellcheck(item['config']['run']['path'],
                                                                    item['config']['run']['args'],
                                                                    combined_params)
                            if exitcode != 0:
                                errors['shellcheck'].append({
                                    'job': job['name'],
                                    'task': item['task'],
                                    '~': output,
                                    'fatal': True,
                                })

            overall_used_resources = overall_used_resources.union(used_resources).union(get_resources)

            # Resources that were fetched with a `get:` but never referred to
            # We ignore triggered resources as they are often only used to
            # trigger and not used in the tasks
            get_remainder = get_resources - used_resources - triggered_resources
            if get_remainder:
                for resource in get_remainder:
                    errors['unused_fetch'].append({
                        'job': job['name'],
                        'resource': resource,
                        'fatal': False
                    })

            # `output:` from tasks that were never referred to
            out_remainder = output_resources - used_resources
            if out_remainder:
                for resource in out_remainder:
                    errors['unused_output'].append({
                        'job': job['name'],
                        'resource': resource,
                        'fatal': False
                    })

        # Resources that were defined in the `resources:` block but never used
        unused_resources = defined_resource_names - overall_used_resources
        if unused_resources:
            for resource in unused_resources:
                errors['unused_resource'].append({
                    'resource': resource,
                    'fatal': False
                })

        return errors


if __name__ == '__main__':
    def usage():
        print """
pipecleaner.py [--ignore-types=unused_fetch,unused_resource]
               [--fatal-warnings]
               pipeline1.yml [pipelineN.yml...]"""
        sys.exit(2)

    try:
        opts, args = getopt.getopt(sys.argv[1:],
                                   '',
                                   ['ignore-types=',
                                    'fatal-warnings'])
    except getopt.GetoptError:
        usage()

    files = args
    ignore_types = []
    fatal_warnings = False

    for flag, arg in opts:
        if flag == '--ignore-types':
            ignore_types = arg.split(',')
        if flag == '--fatal-warnings':
            fatal_warnings = True

    if not files:
        usage()

    BOLD = '\033[1m'
    ENDC = '\033[0m'
    FMT = '%s' + BOLD + '* ' + ENDC + '%s' + ': %s'

    fatal = None
    p = Pipecleaner(ignore_types=ignore_types)
    for filename in files:
        errors = p.validate(filename)

        if [j for i in errors.values() for j in i]:
            print "\n==", BOLD, filename, ENDC, "=="

        for err_type, err_list in errors.items():
            if err_type in ignore_types:
                continue

            for err in err_list:
                if err['fatal']:
                    msg_prefix = '\033[91mERROR '
                else:
                    msg_prefix = '\033[93mWARNING '

                if not fatal:
                    fatal = err['fatal']
                del err['fatal']

                error_strings = []
                for k, v in sorted(err.items()):
                    error_strings.append("%s='%s'" % (k, v))

                print FMT % (msg_prefix, err_type.replace('_', ' ').title(), ', '.join(error_strings))

    if fatal is True:
        sys.exit(10)
    elif fatal is False and fatal_warnings:
        sys.exit(20)
