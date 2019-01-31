$(function() {

    var initSeriesSystemRelationshipForm = function(subform) {

        $("[name=series_system_relationship_type]", subform).change(function(event) {
            var type = $(this).val();

            var $targetContainer = $(this).parents(".form-group:first").siblings('.relationship-subform');
            var index = $(this).parents("[data-index]:first").data("index");

            var template_data = {
                path: AS.quickTemplate($(this).parents("[data-name-path]:first").data("name-path"), {index: index}),
                id_path: AS.quickTemplate($(this).parents("[data-id-path]:first").data("id-path"), {index: index}),
                index: index
            };

            var $related_function_type_subform = $(AS.renderTemplate("template_"+type, template_data));

            $targetContainer.html($related_function_type_subform);

            $(document).triggerHandler("subrecordcreated.aspace", ["series_system_relationship_type", $related_function_type_subform]);
        });

    };

    $(document).bind("subrecordcreated.aspace", function(event, object_name, subform) {
        if (object_name === "series_system_relationship") {
            initSeriesSystemRelationshipForm($(subform));
        }
    });

});
