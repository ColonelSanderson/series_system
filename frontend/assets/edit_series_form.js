$(document).on("loadedrecordform.aspace", function(event) {
    $('#resource_id_0_').attr('type', 'hidden');
    $('#resource_id_0_').closest('div').append($('#resource_id_0_').attr('value'));

    $('#resource_id_1_').hide();
    $('#resource_id_2_').hide();
    $('#resource_id_3_').hide();
});
