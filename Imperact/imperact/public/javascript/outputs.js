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
    var attributes = [filename];
    
    // Get basename and attributes
    var re = /(?:\.([^.]+))?$/;
    var ext = re.exec(filename)[1];
    if (ext) {
	attributes.push(ext);
	var basename = filename.slice(0, -ext.length - 1);
    } else
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
	attributes.push('fulladapt');
    if ($.inArray('levels', attributes) == -1 && $.inArray('aggregated', attributes) == -1)
	attributes.push('irlevel');

    return {basename: basename, attributes: attributes}
}

function endremove(basename, attr, attributes, title) {
    if (basename.endsWith('-' + attr)) {
	attributes.push(attr);
	return basename.slice(0, -attr.length - 1);
    }

    return basename;
}

function effectsetDisplay(attributes) {
    if ($.inArray('nc4', attributes) == -1)
	return '<span>' + attributeTitle(attributes) + '</span>';

    if ($.inArray('indiamerge', attributes) != -1) {
	var subattr = attributes.slice();
	subattr.splice($.inArray('indiamerge', subattr), 1);
	return '<span class="badged">' + $(effectsetDisplay(subattr)).html() + '<img class="indiamerge" src="/images/imperact/icons/indiamerge.png" alt="With India" /></span>';
    }
	
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

    return 'span>' + attributeTitle(attributes) + '</span>';
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
