<div>
  <h1>${fullpath}</h1>

  <h2>Coordinates</h2>
  <dd>
  % for var in coords:
  <dt>${var} (${dims[var]})</dt>
  <dd><ul>
      % for attr in coords[var]:
      % if attr not in ['quantiles', 'mean', 'sdev', 'dims']:
      <li>${attr}: ${coords[var][attr]}</li>
      % endif
      % endfor
    </ul></dd>
  % endfor
  </dd>

  <h2>Variables</h2>
  <dd>
  % for var in variables:
  <dt>${var} (${dims.get(var, "Unknown dimensions")})</dt>
  <dd><ul>
      % if 'quantiles' in variables[var]:
      <li>Min.: ${variables[var]['quantiles'][0]}, Med.:
      ${variables[var]['quantiles'][1]}, Max.:
	${variables[var]['quantiles'][2]}</li>
      <li>Mean: ${variables[var]['mean']},
	Std. Dev. ${variables[var]['sdev']}</li>
      % endif
      % for attr in variables[var]:
      % if attr not in ['quantiles', 'mean', 'sdev', 'dims']:
      <li>${attr}: ${variables[var][attr]}</li>
      % endif
      % endfor
    </ul></dd>
  % endfor
  </dd>

  <h2>Attributes</h2>
  <dd>
  % for attr in attrs:
  <dt>${attr}</dt>
  <dd>${attrs[attr]}</dd>
  % endfor
  </dd>
</div>
