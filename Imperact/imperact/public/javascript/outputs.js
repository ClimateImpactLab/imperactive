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

    return {basename: basename, attributes: attributes}
}

function endremove(basename, attr, attributes, title) {
    if (basename.endsWith('-' + attr)) {
	attributes.push(attr);
	return basename.slice(0, -attr.length - 1);
    }

    return basename;
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

	return attribute;
    });
    if (!$.inArray('noadapt') && !$.inArray('incadapt'))
	titles.push("Full Adaptation");
    console.log(titles);
    return titles.slice(1).join(', ');
}
