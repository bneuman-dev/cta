$(document).ready(function () {
	tables = train_tables();
	html = tables.get_html();
	$('body').append(html);
	$('div.json').hide();
});