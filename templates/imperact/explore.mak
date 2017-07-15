<%inherit file="local:templates.master"/>

<%def name="title()">
Output explorer
</%def>

<%def name="select_subdir(label, name, updater)">
<script type="text/javascript">
  $(function() {
    $('#${name}').change(function() {
      if ($('#${name}').val() == '')
        ${updater}(null);
      else
        ${updater}($('#${name}_parent').val() + '/' + $('#${name}').val());
    });
  });

  function update_subdir_${name}(parent) {
    if (parent == null)
      $('#${name}').prop('disabled', true);
    $('#${name}_parent').val(parent);
    $('#${name}').prop('disabled', true).html('<option value="">Loading...</option>');
    ${updater}(null);
    $.getJSON("/imperact/list_subdir", {subdir: parent}, function(data) {
      $('#${name}').html('<option value="">Select below</option>');
      $.each(data['contents'], function(content) {
        $('#${name}').append('<option value="' + content + '">' + content + '</option>');
      });
      $('#${name}').prop('disabled', false);
    });
  }
</script>

<input type="hidden" id="${name}_parent" value="" />
<label name="${name}">
  ${label}
</label>
<select name="${name}" id="${name}" disabled="disabled">
  <option value="">Loading...</option>
</select>
</%def>

<div class="row">
  ${select_subdir("Sector", 'sector', 'update_subdir_version')}
  ${select_subdir("Version", 'version', 'update_subdir_batch')}
  ${select_subdir("Batch", 'batch', 'update_subdir_rcp')}
  ${select_subdir("RCP", 'rcp', 'update_subdir_gcm')}
  ${select_subdir("GCM", 'gcm', 'update_subdir_aim')}
  ${select_subdir("AIM", 'aim', 'update_subdir_ssp')}
  ${select_subdir("SSP", 'ssp', 'update_subdir_listing')}
</div>

<table id="listing">
  <th>Basename</th>
</table>
