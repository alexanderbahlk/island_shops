$(document).ready(function () {
    var categorySelect = $('#shop_item_category_select');
    var subCategorySelect = $('#shop_item_sub_category_select');
    var subCategoryWrapper = $('#shop_item_sub_category_wrapper');

    // Get sub-category data from form data attribute
    var subCategories = $('form').data('sub-categories') || {};
    
    // Store the initially selected sub-category value
    var initialSubCategoryValue = subCategorySelect.val();

    function updateSubCategories() {
        var categoryId = categorySelect.val();
        var currentValue = subCategorySelect.val();
        subCategorySelect.empty();

        if (categoryId && subCategories[categoryId]) {
            subCategorySelect.append('<option value=""></option>');
            $.each(subCategories[categoryId], function (index, item) {
                var selected = (item[1] == currentValue || item[1] == initialSubCategoryValue) ? ' selected' : '';
                subCategorySelect.append('<option value="' + item[1] + '"' + selected + '>' + item[0] + '</option>');
            });
            subCategoryWrapper.show();
        } else {
            subCategoryWrapper.hide();
        }
    }

    // Initialize on page load
    updateSubCategories();

    // Update when category changes (but don't preserve value on manual changes)
    categorySelect.change(function() {
        initialSubCategoryValue = null; // Clear initial value after first change
        updateSubCategories();
    });
});