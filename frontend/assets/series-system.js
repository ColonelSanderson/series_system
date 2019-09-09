function SeriesSystem() {
    this.setupNavigation();
};

SeriesSystem.prototype.setupNavigation = function() {
    var $createActions = $($('#seriesSystemCreateActions').html());
    var $browseActions = $($('#seriesSystemBrowseActions').html());

    $createActions.appendTo('.repository-header .create-container ul:first');
    $('.repository-header .navbar-nav .browse-container .dropdown-menu .divider:first').before(AS.renderTemplate("seriesSystemBrowseActions"));
};


$(document).ready(function() {
    window.series_system = new SeriesSystem();
});