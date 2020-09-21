import YAML from 'yaml';

import { ErrorPage } from './error';
import { render } from './layout';

const manifestOverride = {
  path: '/instance_groups/name=router/jobs/name=gorouter/properties/router/html_error_template?',
  type: 'replace',
};

render(ErrorPage(), { title: '{{ .StatusText }}' })
  .then(value => {
    process.stdout.write(YAML.stringify([{ ...manifestOverride, value }]));
  })
  .catch(err => {
    process.stderr.write(err);
  });
