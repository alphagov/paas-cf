import React, { ReactElement } from 'react';

export function ErrorPage(): ReactElement {
  return <div className="govuk-grid-row">
    <div className="govuk-grid-column-two-thirds">
      <span className="govuk-caption-xl">{'{{ .Status }}'}</span>
      <h1 className="govuk-heading-xl">{'{{ .StatusText }}'}</h1>
      <p className="govuk-body">
        {'{{ .Message }}'}
      </p>
      <p className="govuk-body">
        <small>{'{{ .Header.Get "X-Cf-RouterError" }}'}</small>
      </p>
    </div>
  </div>;
}
