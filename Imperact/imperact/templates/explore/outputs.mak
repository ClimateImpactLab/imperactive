<%inherit file="local:templates.master"/>

<%def name="title()">
Output explorer
</%def>

<%def name="head_tags()">
<link rel="stylesheet" type="text/css" media="screen" href="${tg.url('/css/imperact/outputs.css')}" />
<script src="${tg.url('/js/imperact/outputs.js')}" type="text/javascript"></script>
</%def>

<%def name="select_subdir(label, name, child)">
<script type="text/javascript">
  parents_${name} = [];
    
  $(function() {
    $('#${name}').change(function() {
      if ($('#${name}').val() == '')
	parents_${child} = null;
      else {
	subdir = $('#${name}').val();
	parents_${child} = parents_${name}.slice();
	parents_${child}.push(subdir);
	window.location.hash = parents_${child}.join('/');
      }
      update_subdir_${child}();
    });
  });

  function fill_${name}(callback) {
    $.getJSON("/explore/list_subdir", {subdir: parents_${name}.join('/')}, function(data) {
      $('#${name}').html('<option value="">Select below</option>');
      $.each(data['contents'], function(content, metadata) {
        if (metadata && metadata.title)
          $('#${name}').append('<option value="' + content + '">' + metadata.title + '</option>');
	else
          $('#${name}').append('<option value="' + content + '">' + content + '</option>');
      });
      $('#${name}').prop('disabled', false);
      callback();
    });
  }

  function load_subdir_${name}(descends) {
    fill_${name}(function() {
      if (descends.length > 0) {
        $('#${name}').val(descends[0]); // happens before change handler set
	parents_${child} = parents_${name}.slice();
	parents_${child}.push(descends[0]);
	load_subdir_${child}(descends.slice(1));
      }
    });
  }
  
  function update_subdir_${name}() {
    if (parents_${name} == null) {
      $('#${name}').prop('disabled', true);
      parents_${child} = null;
      update_subdir_${child}();
      return;
    }
    $('#${name}_parent').val(parent);
    $('#${name}').prop('disabled', true).html('<option value="">Loading...</option>');
    parents_${child} = null;
    update_subdir_${child}();
    fill_${name}(function() {});
  }
</script>

<p>
  <label name="${name}">
    ${label}
  </label>
  <select name="${name}" id="${name}" disabled="disabled">
    <option value="">Loading...</option>
  </select>
</p>
</%def>

<script type="text/javascript">
  parents_listing = [];

  $(function() {
    if (window.location.hash == '')
      update_subdir_sector();
    else {
      load_subdir_sector(window.location.hash.substring(1).split('/'));
    }
  });
      
  update_subdir_listing = load_subdir_listing;
</script>

<div class="row">
  ${select_subdir("Sector", 'sector', 'version')}
  ${select_subdir("Version", 'version', 'batch')}
  ${select_subdir("Batch", 'batch', 'rcp')}
  ${select_subdir("RCP", 'rcp', 'gcm')}
  ${select_subdir("GCM", 'gcm', 'aim')}
  ${select_subdir("AIM", 'aim', 'ssp')}
  ${select_subdir("SSP", 'ssp', 'listing')}
</div>

<table id="listing" border="1">
  <th>Basename</th>
</table>

<div id="display_output" title="Display Output" style="display: none">
  <span id="display_output_title"></span>
  <img id="display_output_img" src="/images/imperact/ajax-loader.gif" />
</div>
