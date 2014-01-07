$(document).ready(function () {
	tables = bus_tables();
	html = make_html(tables);
	$('body').append(html);
	$('div.json').hide();
});