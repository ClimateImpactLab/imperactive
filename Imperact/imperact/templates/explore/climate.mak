<%inherit file="local:templates.master"/>

<%def name="title()">
Climate explorer
</%def>

<%def name="head_tags()">
<link rel="stylesheet" type="text/css" href="${tg.url('/css/imperact/climate.css')}" />
<script src="${tg.url('/js/imperact/climate.js')}" type="text/javascript"></script>
<link rel="stylesheet" type="text/css" href="${tg.url('/css/imperact/jquery.qtip.min.css')}" />
<script src="${tg.url('/js/imperact/jquery.qtip.min.js')}" type="text/javascript"></script>
<link rel="stylesheet" href="${tg.url('/css/imperact/font-awesome.min.css')}" />
<link href="${tg.url('/css/imperact/buttonLoader.css')}" rel="stylesheet" />
<script src="${tg.url('/js/imperact/jquery.buttonLoader.js')}"></script>
<link rel="stylesheet" type="text/css" href="${tg.url('/css/imperact/jquery.qtip.min.css')}" />
<script src="${tg.url('/js/imperact/jquery.qtip.min.js')}" type="text/javascript"></script>
</%def>

<button id="reload" class="btn btn-primary my-btn has-spinner" style="float: right">Refresh Listing</button>

<input type="text" id="pathSearch" onkeyup="updateTable()" placeholder="Search for climate variables...">
 
<table id="pathResults">
  <thead>
    <tr class="header">
      <th style="min-width: 64px; padding: 6px">Type</th>
      <th style="width: 100%;">Path</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td><img src="/images/imperact/climate-icons/ajax-loader.gif" />
      <td class="path">Loading, please wait...</td>
    </tr>
  </tbody>
</table>

<script type="text/javascript">
    $(function() {
	loadTable();
	
	$('#reload').click(function() {
	    var $button = $(this);
	    $button.buttonLoader('start');
	    $.get('/climate/refresh_listing', function() {
		loadTable();
		$button.buttonLoader('stop');
	    });
	});
    });

function loadTable() {
    $.getJSON("${tg.url('/climate-listing.json')}", function(data) {
	// Decide on order
	var keys = Object.keys(data).sort(function(one, two) {
	    var prioone = data[one].priority || 100;
	    var priotwo = data[two].priority || 100;
	    if (prioone == priotwo)
		return (one < two ? -1 : 1);
	    return prioone - priotwo;
	});
	var $tbody = $('#pathResults tbody');
	$tbody.empty();
	for (var ii = 0; ii < keys.length; ii++) {
	    $row = $('<tr><td><img src="/images/imperact/climate-icons/' + data[keys[ii]].type + '.png" /></td><td class="path">' + keys[ii] + '</td><input type="hidden" name="path" value="' + (data[keys[ii]].path || keys[ii]) + '" /></tr>');
	    $row.find('img').qtip({content: {text: typeDescriptions[data[keys[ii]].type]}});
	    $tbody.append($row);
	}

	$('#pathResults tbody tr').click(function() {
	    $('#infoPanel').html('<img src="/images/imperact/ajax-loader.gif" />');
	    $('#infoPanel').load("${tg.url('/climate/show')}",
				 { path: $(this).find('input[name=path]').val() });
	    $('#infoPanel').animate({
		height: "140px"
	    });
	});
    });
}
	
// Modified from https://www.w3schools.com/howto/howto_js_filter_table.asp
function updateTable() {
    var $input = $("#pathSearch");
    var filter = $input.val().toUpperCase();
    $tds = $(".path");

    // Loop through all table rows, and hide those who don't match the search query
    for (var ii = 0; ii < $tds.length; ii++) {
	$td = $($tds[ii]);
      	if ($td.html().toUpperCase().indexOf(filter) > -1)
	    $td.parent().show();
	else
	    $td.parent().hide();
    }
};
</script>

<%def name="bottom_content()">
<div id="infoPanel"></div>
</%def>
