function interpretAll(filenames) {
    basenames = {}; // {basename: [attributes...]}
    $.each(filenames, function(ii, filename) {
	var split = interpret(filename);
	if (!basenames[split.basename])
	    basenames[split.basename] = [];
	basenames[split.basename].push(split.attributes);
    });

    return basenames;
}

function interpret(filename) {
    var attributes = [];
    
    // Get basename and attributes
    var re = /(?:\.([^.]+))?$/;
    var ext = re.exec(filename)[1];
    if (ext)
	var basename = filename.slice(0, -ext.length - 1);
    else
	var basename = filename;

    var oldbasename = "";
    while (basename != oldbasename) {
	oldbasename = basename
	basename = endremove(basename, 'aggregated', attributes);
	basename = endremove(basename, 'levels', attributes);
	basename = endremove(basename, 'costs', attributes);
	basename = endremove(basename, 'histclim', attributes);
	basename = endremove(basename, 'noadapt', attributes);
	basename = endremove(basename, 'incadapt', attributes);
	basename = endremove(basename, 'indiamerge', attributes);
    }
    if ($.inArray('noadapt', attributes) == -1 && $.inArray('incadapt', attributes) == -1)
	attributes.unshift('fulladapt');
    if ($.inArray('levels', attributes) == -1 && $.inArray('aggregated', attributes) == -1)
	attributes.push('irlevel');

    if (ext)
	attributes.push(ext);

    attributes.unshift(filename);
    
    return {basename: basename, attributes: attributes}
}

function endremove(basename, attr, attributes, title) {
    if (basename.endsWith('-' + attr)) {
	attributes.unshift(attr);
	return basename.slice(0, -attr.length - 1);
    }

    return basename;
}

function effectsetDisplay(attributes, badge) {
    if ($.inArray('nc4', attributes) == -1)
	return '<span>' + attributeTitle(attributes) + '</span>';

    if ($.inArray('indiamerge', attributes) != -1) {
	var subattr = attributes.slice();
	subattr.splice($.inArray('indiamerge', subattr), 1);
	return '<span class="badged">' + $(effectsetDisplay(subattr)).html() + '<img class="indiamerge" src="/images/imperact/icons/indiamerge.png" alt="With India" /></span>';
    }

    if (badge)
	return '<span class="badged">' + $(effectsetDisplay(attributes)).html() + '<img class="' + badge + '" src="/images/imperact/icons/' + badge + '.png" alt="' + badge + '" /></span>';
	
    var iconPrefix = null;
    if (attributes.length == 5 && $.inArray('costs', attributes) != -1 && $.inArray('fulladapt', attributes) != -1)
	iconPrefix = 'costs';
    if (attributes.length == 4 && $.inArray('fulladapt', attributes) != -1)
	iconPrefix = 'fulladapt';
    if (attributes.length == 4 && $.inArray('noadapt', attributes) != -1)
	iconPrefix = 'noadapt';
    if (attributes.length == 4 && $.inArray('incadapt', attributes) != -1)
	iconPrefix = 'incadapt';
    if (attributes.length == 5 && $.inArray('histclim', attributes) != -1 && $.inArray('fulladapt', attributes) != -1)
	iconPrefix = 'histclim';

    if (iconPrefix) {
	if ($.inArray('irlevel', attributes) != -1)
	    return '<span><img src="/images/imperact/icons/' + iconPrefix + '.png" alt="' + attributeTitle(attributes) + '" /></span>';
	if ($.inArray('levels', attributes) != -1)
	    return '<span><img src="/images/imperact/icons/' + iconPrefix + '-levels.png" alt="' + attributeTitle(attributes) + '" /></span>';
	if ($.inArray('aggregated', attributes) != -1)
	    return '<span><img src="/images/imperact/icons/' + iconPrefix + '-aggregated.png" alt="' + attributeTitle(attributes) + '" /></span>';
    }

    return '<span>' + attributeTitle(attributes) + '</span>';
}

function attributeTitle(attributes) {
    var titles = $.map(attributes, function(attribute) {
	if (attribute == "nc4")
	    return null;
	if (attribute == 'aggregated')
	    return "Aggregated";
	if (attribute == 'levels')
	    return "Levels";
	if (attribute == 'costs')
	    return "Costs";
	if (attribute == 'histclim')
	    return "Historical Climate";
	if (attribute == 'noadapt')
	    return "No Adaptation";
	if (attribute == 'incadapt')
	    return "Income-only Adaptation";
	if (attribute == 'indiamerge')
	    return "With India";
	if (attribute == 'fulladapt')
	    return "Full Adaptation";
	if (attribute == 'irlevel')
	    return "IR Level";
	
	return attribute;
    });

    return titles.slice(1).join(', ');
}

function findHistoricalClimate(attributes, attributeses) {
    // Is there an exact match?
    if ($.inArray('noadapt', attributes) != -1)
	return null;

    var newAttributes = attributes.slice();
    newAttributes.push('histclim');
    var found = findEffectset(newAttributes, attributeses);
    if (found)
	return found;

    if ($.inArray('incadapt', newAttributes) != -1) {
	newAttributes[$.inArray('incadapt', newAttributes)] = 'fulladapt';
	return findEffectset(newAttributes, attributeses);
    }

    return null;
}

function findEffectset(attributes, attributeses) {
    for (var ii = 0; ii < attributeses.length; ii++) {
	var compare = attributeses[ii];
	if (compare.length != attributes.length)
	    continue;

	var hasAll = true;
	for (var jj = 1; jj < attributes.length; jj++) // start after filename
	    if ($.inArray(attributes[jj], compare) == -1) {
		hasAll = false;
		break;
	    }

	if (hasAll)
	    return compare;
    }
}

function load_subdir_listing() {
    if (parents_pattern == null)
	return;
    $.getJSON("/explore/list_subdir", {subdir: parents_pattern.join('/')}, function(data) {
	make_table(data.contents, function($link, basename, attributes, metainfo) {
	    $link.click(function() {
		displayOutput(attributes);
	    });
	});
    });
}

function make_table(contents, link_callback, skiphist) {
    $('#listing').html("  <tr><th>Basename</th><th>Available</th></tr>");
    var basenames = interpretAll($.map(contents, function(metainfo, content) {return content}));
    $.each(basenames, function(basename, attributeses) {
	// Collect derivatives of basename into groups
	var groups = [];
	var loners = [];
	var $links = [];
	$.each(attributeses, function(ii, attributes) {
	    if ($.inArray('irlevel', attributes) != -1)
		var grpcls = 'irlevel';
	    else if ($.inArray('levels', attributes) != -1)
		var grpcls = 'levels';
	    else if ($.inArray('aggregated', attributes) != -1)
		var grpcls = 'aggregated';
	    else
		var grpcls = 'loner';
	    if (grpcls == 'loner') {
		var group = attributes.slice(1).join('-');
		loners.push(group);
	    } else {
		groupattrs = attributes.slice(1);
		groupattrs.splice($.inArray(grpcls, groupattrs), 1);
		var group = groupattrs.join('-');
		groups.push(group);
	    }
		
	    var $link = $('<a class="' + group + ' ' + grpcls + '"></a>');
	    $link.qtip({content: {text: attributeTitle(attributes)}});
	    $link.html(effectsetDisplay(attributes));
	    link_callback($link, basename, attributes, contents[attributes[0]]);
	    
	    $links.push($link);

	    if (skiphist)
		return;
		
	    // De we have a corresponding historical climate to subtract?
	    var histclim = findHistoricalClimate(attributes, attributeses);
	    if (histclim) {
		groups.push(group + '-histclim');
		var $link = $('<a class="' + group + '-histclim ' + grpcls + '"></a>');
		$link.qtip({content: {text: attributeTitle(attributes) + " minus historical climate"}});
		$link.html(effectsetDisplay(attributes, 'histclim'));
		$link.click(function() {
		    displayOutputHistclim(attributes, histclim[0].substr(0, histclim[0].length - 4));
		});
		
		$links.push($link);
	    }
	});

	// Group links together
	$linksdiv = $('<div></div>');
	for (ii = 0; ii < $links.length; ii++)
	    $linksdiv.append($links[ii]);

	// Group links together
	var $groupdivs = $.map($.unique(groups), function(group) {
	    var $irlevel = $linksdiv.find('.' + group + '.' + 'irlevel');
	    var $levels = $linksdiv.find('.' + group + '.' + 'levels');
	    var $aggregated = $linksdiv.find('.' + group + '.' + 'aggregated');
	    
	    var $groupdiv = $('<div display="inline-block"></div>');
	    $groupdiv.append($irlevel);
	    $groupdiv.append($levels);
	    $groupdiv.append($aggregated);
	    return $groupdiv;
	});
	var $lonerdivs = $.map($.unique(loners), function(group) {
	    var $groupdiv = $('<div display="inline-block"></div>');
	    $groupdiv.append($linksdiv.find('.' + group + '.loner'));
	    return $groupdiv;
	});

	var $row = $('<tr><td>' + basename + '</td><td class="available"></td></tr>');
	for (ii = 0; ii < $groupdivs.length; ii++)
	    $row.find('.available').append($groupdivs[ii]);
	for (ii = 0; ii < $lonerdivs.length; ii++)
	    $row.find('.available').append($lonerdivs[ii]);
	$('#listing').append($row);
    });
}

function timeseriesData(attributes) {
    var filename = attributes[0];
    
    var data = {
	targetdir: parents_pattern.join('/'),
	basename: filename.substr(0, filename.lastIndexOf('.')),
    };
    if (filename.indexOf("-costs") != -1)
	data.variable = 'costs_ub';
    else
	data.variable = 'rebased';
      
    if (filename.indexOf("-aggregated") != -1)
	data.region = 'global';
    else
	data.region = 'IND.33.542.2153';

    return data;
}

function displayOutput(attributes) {
    var data = timeseriesData(attributes);
    displayOutputDialog(attributes[0] + ': ' + attributeTitle(attributes),
			'/explore/timeseries', data);
}

function displayOutputHistclim(attributes, histclim) {
    var data = timeseriesData(attributes);
    var newData = {
	targetdir: data.targetdir,
	region: data.region,
	basevars: [data.basename + ':' + data.variable, histclim + ':-' + data.variable].join(',')
    };
    displayOutputDialog(attributes[0] + ': ' + attributeTitle(attributes) + " minus historical climate",
			'/explore/timeseries_sum', newData);
}

function displayOutputDialog(title, generator, data) {
    $('#display_output_title').html(title);

    $('#display_output_region').val(data.region);
    $('#display_output_region').autocomplete({
	source: function(request, response) {
	    $.getJSON("/explore/search_regions",
		      {'basename': data.basename, query: $('#display_output_region').val()},
		      function(data) {
			  response($.map(data.options, function(val) {
			      return {label: val[1], value: val[0]};
			  }));
		      });
	},
	minLength: 2,
	select: function(event, ui) { displayOutputUpdate(generator, data) }
    });

    $('#display_output_variable')
	.off('change')
	.attr('disabled', true)
	.html('<option value="' + data.variable + '">' + data.variable + '</option>');
    $.getJSON("/explore/get_variables",
	      {'targetdir': data.targetdir, 'basename': data.basename},
	      function(json) {
		  console.log(json);
		  $('#display_output_variable').empty();
		  for (var ii = 0; ii < json.variables.length; ii++) {
		      var newvar = json.variables[ii];
		      if (newvar == 'year' || newvar == 'time' || newvar == 'region')
			  continue;
		      
		      $('#display_output_variable').append('<option value="' + newvar + '">' + newvar + '</option>');
		  }

		  $('#display_output_variable')
		      .val(data.variable)
		      .change(function() { displayOutputUpdate(generator, data) })
		      .attr('disabled', false)
	      });

    displayOutputUpdate(generator, data);
    
    $('#display_output').dialog({width: 650}).on('dialogclose', function(event) {
	$('#display_output_region').val('');
	$('#display_output_img').attr('src', "/images/imperact/ajax-loader.gif");
    });
}

function displayOutputUpdate(generator, data) {
    data.region = $('#display_output_region').val();
    data.variable = $('#display_output_variable').val();
    var src = generator + '?' + $.param(data);
    
    $('#display_output_img').attr('src', "/images/imperact/ajax-loader.gif");
    setTimeout(function() {
	$('#display_output_img').attr('src', src)
    }, 100);
}
