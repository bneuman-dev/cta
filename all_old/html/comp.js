$(document).ready(function () {
	tables = comp_tables();
	html = tables.get_html();
	$('body').append(html);
	$('div.json').hide();
});