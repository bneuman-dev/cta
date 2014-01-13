$(document).ready(function () {
	tables = bus_tables();
	html = tables.get_html();
	$('body').append(html);
	$('div.json').hide();
});