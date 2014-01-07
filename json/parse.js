var ReportsTable = function (headings, reports_element) {
	this.reports = get_reports(reports_element);
	this.label = get_label(reports_element);
	this.headings = headings;
	var that = this;

	this.make_html = function() {
		var title_html = make_title_html();
		var header_html = make_header_html();
		var table_rows = make_rows_html();
		var html = "<table border>" + title_html + header_html + table_rows + "</table>";
		return html;
	};

	function make_title_html() {
		var html = "<caption>" + that.label + "</caption>";
		return html;
	}

	function make_header_html() {
		row = "<tr>";
		for (i = 0; i < that.headings.length; i++) {
			cell = "<th>" + that.headings[i] + "</th>";
			row += cell;
		}

		row += "</tr>";

		return row;
	}

	function get_reports(reports_element) {
		json = reports_element.innerHTML;
		reports = JSON.parse(json);
		return reports;
	};

	function get_label(reports_element) {
		var label = $(reports_element).attr('id');
		return label;
	}

	function make_rows_html () {
		var rows = [];

		for (i = 0; i < that.reports.length; i++) {
			report = that.reports[i];
			row = make_row_html_from_report(report);
			rows.push(row);
		};
 
	  return rows;
	}

	 function make_row_html_from_report (report) {
		var row = "<tr>";

		for (j = 0; j < that.headings.length; j++) {
			key = that.headings[j];
			var cell = "<td>" + report[key] + "</td>";
			row += cell;
		};

		row += "</tr>";

		return row;
	}
}


function get_reports () {
	return $('div.json');
}

function make_tables (headings, reports) {
	var tables = [];
	for (i=0; i < reports.length; i++) {
		table = new ReportsTable(headings, reports[i]);
		tables.push(table);
	};

	return tables;
}

function make_html (tables) {
	html = ""
	for (i=0; i<tables.length; i++) {
		table_html = tables[i].make_html();
		html += table_html;
	}
	return html;
}

function bus_tables () {
	headings = ['timestamp', 'stop_id', 'stop_name', 'route', 'route_dir', 'predicted_time', 'feet_left_to_stop', 'delayed', 'vehicle_id'];
	reports = get_reports();
	tables = make_tables(headings, reports);
	return tables;
}

function train_tables () {
	headings = ['station_id', 'stop_id', 'station_name', 'platform_name',
	 'run_number', 'route_name', 'destination_stpd_id', 'destination_name',
	 'direction_code', 'arrival_time', 'is_approaching',
	 'is_scheduled_prediction', 'fault_detected', 'delay_detected', 'latitude', 'longitude'];
	 reports = get_reports();
	tables = make_tables(headings, reports);
	return tables;
}
