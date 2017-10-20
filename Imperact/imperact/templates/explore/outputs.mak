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

  function fill_${name}(callback, skipwalk) {
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

    if (skipwalk)
	return;

    % if name not in ['sector', 'version']:
    if (walking_jqxhr)
	walking_jqxhr.abort();
    var jqxhr = $.getJSON("/explore/walk_subdir", {subdir: parents_${name}.join('/')}, function(data) {
	// Check if still active
	if (walking_jqxhr == jqxhr) {
	    walking_jqxhr = null;
	    make_table(data.contents, function($link, basename, attributes, metainfo) {
		$link.prepend(metainfo + ' &times; ');
	    }, true);
	}
    });
    walking_jqxhr = jqxhr;
    % endif
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
    }, descends.length > 0);
  }

  // Called after select box changed; look in parents for full path
  function update_subdir_${name}() {
    if (parents_${name} == null) {
	$('#${name}').prop('disabled', true);
	parents_${child} = null;
	update_subdir_${child}();
    } else {
	$('#${name}_parent').val(parent);
	$('#${name}').prop('disabled', true).html('<option value="">Loading...</option>');
	parents_${child} = null;
	update_subdir_${child}();
	fill_${name}(function() {});
    }
  }
</script>

<%def name="select_subdir_pattern(label, name, index)">
## Called for each directory selection that allows pattern paths
<script type="text/javascript">
  $(function() {
      $('#${name}').change(function() {
	  subdir = $('#${name}').val();
	  parents_pattern[${index}] = subdir;
	  window.location.hash = parents_pattern.join('/');
      });
  });

  function fill_${name}(callback, skipwalk) {
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

    if (skipwalk)
	return;

    % if name not in ['sector', 'version']:
    if (walking_jqxhr)
	walking_jqxhr.abort();
    var jqxhr = $.getJSON("/explore/walk_subdir", {subdir: parents_${name}.join('/')}, function(data) {
	// Check if still active
	if (walking_jqxhr == jqxhr) {
	    walking_jqxhr = null;
	    make_table(data.contents, function($link, basename, attributes, metainfo) {
		$link.prepend(metainfo + ' &times; ');
	    }, true);
	}
    });
    walking_jqxhr = jqxhr;
    % endif
  }

  // Load a directory ancestry into the select boxes
  function load_subdir_${name}(descends) {
      fill_${name}(function() {
	  if (descends.length > 0) {
              $('#${name}').val(descends[0]); // happens before change handler set
	      parents_pattern[${index}] = 
	parents_${child} = parents_${name}.slice();
	parents_${child}.push(descends[0]);
	load_subdir_${child}(descends.slice(1));
      }
    }, descends.length > 0);
  }
  
  function update_subdir_${name}() {
    if (parents_${name} == null) {
	$('#${name}').prop('disabled', true);
	parents_${child} = null;
	update_subdir_${child}();
    } else {
	$('#${name}_parent').val(parent);
	$('#${name}').prop('disabled', true).html('<option value="">Loading...</option>');
	parents_${child} = null;
	update_subdir_${child}();
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

<script type="text/javascript">
  parents_pattern = [];
  walking_jqxhr = null;

  $(function() {
    if (window.location.hash == '')
      update_subdir_sector();
    else {
      load_subdir_sector(window.location.hash.substring(1).split('/'));
    }
  });

  update_subdir_pattern = load_subdir_pattern = function(descends) {
      
  }
</script>

<div class="row">
  ${select_subdir("Sector", 'sector', 'version')}
  ${select_subdir("Version", 'version', 'batch')}
  ${select_subdir("Batch", 'batch', 'pattern')}
  ${select_subdir_pattern("RCP", 'rcp', 0)}
  ${select_subdir_pattern("GCM", 'gcm', 1)}
  ${select_subdir_pattern("AIM", 'aim', 2)}
  ${select_subdir_pattern("SSP", 'ssp', 3)}
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
