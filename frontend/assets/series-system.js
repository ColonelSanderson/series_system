function SeriesSystem() {
    this.setupNavigation();
};

SeriesSystem.prototype.setupNavigation = function() {
    var $createActions = $($('#seriesSystemCreateActions').html());
    var $browseActions = $($('#seriesSystemBrowseActions').html());

    $createActions.appendTo('.repository-header .create-container ul:first');
    $browseActions.appendTo('.repository-header .browse-container ul:first');
};


$(document).ready(function() {
    window.series_system = new SeriesSystem();
});