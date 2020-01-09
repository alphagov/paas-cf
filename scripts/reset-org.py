#!/usr/bin/env python

import argparse
import re
import subprocess
import sys
import time
import os

script_path = os.path.relpath(__file__)
with open(os.path.expanduser('~/.paas-script-usage'), 'a') as f:
  f.write(script_path + "\n")

# python2 compatibility
try: input = raw_input
except NameError: pass

class SubprocessException(Exception):
    pass

class OrgReset(object):
    def __init__(self, org, initial_space, org_managers, users, users_are_org_managers, users_are_space_managers, users_are_space_developers, org_quota):
        self.org = org
        self.initial_space = initial_space
        self.org_managers = org_managers
        self.users = users
        self.users_are_org_managers = users_are_org_managers
        self.users_are_space_managers = users_are_space_managers
        self.users_are_space_developers = users_are_space_developers
        self.org_quota = org_quota

    def confirm(self):
        if not self.confirm_user_input('Are you sure you want to delete org %s? (y/n): ' % self.org):
            sys.exit("'No future change is possible.' (phew, not deleted)")

    def confirm_user_input(self, question):
        response = input(question)
        return response == "y"

    def whoami(self):
        self.user = self.parse_current_user(self.run(['cf', 'target']))

    def delete_org(self):
        self.run_with_retry(['cf', 'delete-org', self.org, '-f'], 20, lambda err:
            'one or more resources within could not be deleted' in err.output
        )

    def create_org(self):
        self.run(['cf', 'create-org', self.org])
        self.run(['cf', 'unset-org-role', self.user, self.org, 'OrgManager'])
        if self.org_quota:
            self.run(['cf', 'set-quota', self.org, self.org_quota])

    def create_space(self):
        self.run(['cf', 'create-space', self.initial_space, '-o', self.org])
        self.run(['cf', 'unset-space-role', self.user, self.org, self.initial_space, 'SpaceManager'])
        self.run(['cf', 'unset-space-role', self.user, self.org, self.initial_space, 'SpaceDeveloper'])

    def set_roles(self):
        for org_manager in self.org_managers:
            self.run(['cf', 'set-org-role', org_manager, self.org, 'OrgManager'])

        for user in self.users:
            if self.users_are_org_managers:
                self.run(['cf', 'set-org-role', user, self.org, 'OrgManager'])
            if self.users_are_space_managers:
                self.run(['cf', 'set-space-role', user, self.org, self.initial_space, 'SpaceManager'])
            if self.users_are_space_developers:
                self.run(['cf', 'set-space-role', user, self.org, self.initial_space, 'SpaceDeveloper'])

    def run(self, command):
        print('Running \'%s\'' % ' '.join(command))
        try:
            output = subprocess.check_output(command)
            print(output)
            return output
        except subprocess.CalledProcessError as err:
            raise SubprocessException('Aborting: \'%s\' failed with exit code %d\n%s' % (err.cmd, err.returncode, err.output))

    def run_with_retry(self, command, retry_count, retry_func):
        print('Running with retry \'%s\'' % ' '.join(command))
        try:
            output = subprocess.check_output(command)
            print(output)
            return output
        except subprocess.CalledProcessError as err:
            if retry_func(err):
                print(err.output)
                retry_count -= 1
                if retry_count <= 0:
                    raise SubprocessException('Timed out retrying \'%s\'' % ' '.join(command))

                print('Sleeping for 30 secs before retrying')
                time.sleep(30)
                return self.run_with_retry(command, retry_count, retry_func)
            else:
                raise SubprocessException('Aborting: \'%s\' failed with exit code %d\n%s' % (err.cmd, err.returncode, err.output))

    def parse_current_user(self, target_output):
        match = re.search(r'[Uu]ser:\s+(\S+)', target_output)
        return match.group(1)


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('-o', metavar='ORG_NAME', help='Which org to wipe and recreate', required=True)
    parser.add_argument('-s', metavar='INITIAL_SPACE', help='Initial space to create (default is sandbox)', default='sandbox')
    parser.add_argument('-m', metavar='ORG_MANAGER_EMAIL', help='Emails of users who will manage the new org', nargs='*', default=[])
    parser.add_argument('-u', metavar='USER_EMAIL', help='Emails of team members to add to the org', nargs='*', default=[])
    parser.add_argument('--org-managers', help='Add the OrgManager role for the listed team members', action='store_true', default=False)
    parser.add_argument('--space-managers', help='Add the SpaceManager role for the listed team members in the initial space', action='store_true', default=False)
    parser.add_argument('--space-developers', help='Add the SpaceDeveloper role for the listed team members in the initial space', action='store_true', default=False)
    parser.add_argument('--quota', help='Name of the org quota to use')

    args = parser.parse_args()

    org_reset = OrgReset(args.o, args.s, args.m, args.u, args.org_managers, args.space_managers, args.space_developers, args.quota)
    org_reset.confirm()
    org_reset.whoami()
    org_reset.delete_org()
    org_reset.create_org()
    org_reset.create_space()
    org_reset.set_roles()
