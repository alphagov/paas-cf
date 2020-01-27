#!/usr/bin/env python
import argparse
from github import Github

import os

script_path = os.path.relpath(__file__)
with open(os.path.expanduser('~/.paas-script-usage'), 'a') as f:
  f.write(script_path + "\n")

BOLD = '\033[1m'
ENDC = '\033[0m'

class ForkChecker(object):
    def __init__(self, github_token):
        self.github_token = github_token

    def check(self, organization, prefix, extra_repos):
        g = Github(self.github_token)
        for repo in g.get_organization(organization).get_repos(type='fork'):
            if repo.name.startswith(prefix) or repo.name in extra_repos:
                comparison = repo.compare(
                    repo.owner.login + ':' + repo.default_branch,
                    repo.parent.owner.login + ':' + repo.parent.default_branch
                )

                open_prs = []
                for pull in repo.parent.get_pulls():
                    if pull.head.user.login == organization:
                        open_prs.append(pull)

                if comparison.ahead_by or open_prs:
                    print (BOLD + "\n== %s/%s ==" + ENDC) % (organization, repo.name)

                if comparison.ahead_by:
                    print "\033[91m * " + ENDC + "Upstream ahead by %s commits: %s" % (comparison.ahead_by, comparison.html_url)

                for pull in open_prs:
                    print "\033[93m * " + ENDC + "Open pull request: %s" % pull.html_url
        print


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('organization', help='Organization to search for forks', nargs='+')
    parser.add_argument('--prefix', help='Repository name prefix to filter on', default='')
    parser.add_argument('--extra-repo', help='Repository not matching the prefix to be included', action='append', default=[])
    parser.add_argument('--github-token', help='Github personal API token to increase rate limit')
    args = parser.parse_args()

    f = ForkChecker(args.github_token)
    f.check(args.organization[0], args.prefix, args.extra_repo)
