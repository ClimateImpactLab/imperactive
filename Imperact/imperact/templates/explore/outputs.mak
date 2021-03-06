<%inherit file="local:templates.master"/>

<%def name="title()">
Output explorer
</%def>

<%def name="head_tags()">
<link rel="stylesheet" type="text/css" href="${tg.url('/css/imperact/outputs.css')}" />
<script src="${tg.url('/js/imperact/outputs.js')}" type="text/javascript"></script>
<link rel="stylesheet" type="text/css" href="${tg.url('/css/imperact/jquery.qtip.min.css')}" />
<script src="${tg.url('/js/imperact/jquery.qtip.min.js')}" type="text/javascript"></script>
</%def>

<%def name="select_subdir(label, name, child)">
## Called for each directory selection
<script type="text/javascript">
  parents_${name} = []; // list of parent directories
    
  $(function() {
    // Respond to change in selection
    $('#${name}').change(function() {
      if ($('#${name}').val() == '') // The unselected option
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
    // Populate my selectbox
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

  // Load a directory ancestry into the select boxes
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

  // Called when parent select box changed; look in parents for full path
  function update_subdir_${name}() {
    if (parents_${name} == null) {
	$('#${name}').prop('disabled', true);
	parents_${child} = null;
	update_subdir_${child}();
    } else {
	$('#${name}').prop('disabled', true).html('<option value="">Loading...</option>');
	parents_${child} = null;
	update_subdir_${child}(); // first disable all below
	fill_${name}(function() {});
    }
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

<%def name="select_subdir_pattern(label, name, index)">
## Called for each directory selection that allows pattern paths
<script type="text/javascript">
  $(function() {
      $('#${name}').change(function() {
	  subdir = $('#${name}').val();
	  pattern[${index}] = subdir;
	  window.location.hash = parents_pattern.join('/') + '/' + pattern.join('/');
	  fill_pattern();
      });
  });
</script>

<p>
  <label name="${name}">
    ${label}
  </label>
  <select name="${name}" id="${name}" class="pattern" disabled="disabled">
    <option value="*">Any</option>
  </select>
</p>
</%def>

<script type="text/javascript">
  parents_pattern = [];
  pattern = [];
  walking_jqxhr = null;

  $(function() {
    if (window.location.hash == '')
      update_subdir_sector();
    else {
      load_subdir_sector(window.location.hash.substring(1).split('/'));
    }
  });

  function fill_pattern() {
      // Populate pattern selectboxes
      $.getJSON("/explore/list_subdirpattern", {
	  subdir: parents_pattern.join('/'),
	  pattern: pattern.join('/')
      }, function(data) {
	  $('.pattern').html('<option value="*">Any</option>');
	  $.each(data['contents'], function(group, options) {
	      for (var ii = 0; ii < options.length; ii++) {
		  if (pattern[group] == options[ii])
		      $($('.pattern')[group]).append('<option value="' + options[ii] + '" selected="selected">' + options[ii] + '</option>');
		  else
		      $($('.pattern')[group]).append('<option value="' + options[ii] + '">' + options[ii] + '</option>');
	      }
	  });
	  $('.pattern').prop('disabled', false);
      });

      if (pattern.join('/').indexOf('*') === -1)
	  return load_subdir_listing();

      // Show all available results
      if (walking_jqxhr)
	  walking_jqxhr.abort();
      var jqxhr = $.getJSON("/explore/walk_subdirpattern", {
	  subdir: parents_pattern.join('/'),
	  pattern: pattern.join('/')
      }, function(data) {
	  // Check if still active
	  if (walking_jqxhr == jqxhr) {
	      walking_jqxhr = null;
	      make_table(data.contents, function($link, basename, attributes, metainfo) {
		  $link.prepend(metainfo + ' &times; ');
	      }, true);
	  }
      });
      walking_jqxhr = jqxhr;
  }

  // Load a directory ancestry into the select boxes
  function load_subdir_pattern(descends) {
      pattern = descends;
      while (pattern.length < 5)
	  pattern.push('*');
      fill_pattern();
  }

  function update_subdir_pattern() {
    if (parents_pattern == null) {
	$('.pattern').prop('disabled', true);
    } else {
	$('.pattern').prop('disabled', true).html('<option value="*">Loading...</option>');
	pattern = ['*', '*', '*', '*', '*'];
	fill_pattern();
    }
  }
</script>

<div class="row">
  ${select_subdir("Sector", 'sector', 'version')}
  ${select_subdir("Version", 'version', 'pattern')}
  ${select_subdir_pattern("Batch", 'batch', 0)}
  ${select_subdir_pattern("RCP", 'rcp', 1)}
  ${select_subdir_pattern("GCM", 'gcm', 2)}
  ${select_subdir_pattern("AIM", 'aim', 3)}
  ${select_subdir_pattern("SSP", 'ssp', 4)}
</div>

<table id="listing" border="1">
  <th>Basename</th>
</table>

<div id="display_output" title="Display Output" style="display: none">
  <h2 id="display_output_title"></h2>
  <div>
    <label for="display_output_region">Region:</label>
    <input type="text" name="region" id="display_output_region" />
    <label for="display_output_variable">Variable:</label>
    <select name="variable" id="display_output_variable"></select>
  </div>
  <center>
    <img id="display_output_img" src="/images/imperact/ajax-loader.gif" />
  </center>
</div>
