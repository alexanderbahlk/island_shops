function initializeBestInPlace() {
    jQuery(".best_in_place").best_in_place();


}

function initializeCategorySearchAutocomplete() {
    // Use more flexible selectors that work with ActiveAdmin's batch action forms
    $(document).on('focus', 'input[id*="category_search"], input[name*="category_search"]', function () {
        var $input = $(this);
        var $select = $('select[id*="category_id"], select[name*="category_id"]');

        if (!$input.hasClass('autocomplete-initialized')) {
            $input.addClass('autocomplete-initialized');

            $input.autocomplete({
                source: function (request, response) {
                    $.ajax({
                        url: '/admin/shop_items/category_autocomplete',
                        dataType: 'json',
                        data: {
                            term: request.term
                        },
                        success: function (data) {
                            response(data);
                        }
                    });
                },
                minLength: 2,
                select: function (event, ui) {
                    // Set the selected category in the dropdown
                    $select.val(ui.item.id);
                    $input.val(ui.item.label);
                    return false;
                },
                focus: function (event, ui) {
                    $input.val(ui.item.label);
                    return false;
                }
            });
        }
    });

    // Clear dropdown when search field is manually changed
    $(document).on('input', 'input[id*="category_search"], input[name*="category_search"]', function () {
        var $select = $('select[id*="category_id"], select[name*="category_id"]');
        if ($(this).val() === '') {
            $select.val('');
        }
    });

    // Clear search field when dropdown is manually changed
    $(document).on('change', 'select[id*="category_id"], select[name*="category_id"]', function () {
        var $input = $('input[id*="category_search"], input[name*="category_search"]');
        if ($(this).val() === '') {
            $input.val('');
        } else {
            // Set search field to match selected option
            var selectedText = $(this).find('option:selected').text();
            $input.val(selectedText);
        }
    });
}

function initializeAutocompleteOnModal() {
    // Find the actual form inputs in the modal
    var $form = $('.batch_actions_form');
    var $searchInput = $form.find('input[type="text"]').filter(function () {
        return $(this).attr('name') && $(this).attr('name').includes('category_search');
    });
    var $selectInput = $form.find('select').filter(function () {
        return $(this).attr('name') && $(this).attr('name').includes('category_id');
    });

    if ($searchInput.length && $selectInput.length && !$searchInput.hasClass('autocomplete-initialized')) {
        $searchInput.addClass('autocomplete-initialized');

        $searchInput.autocomplete({
            source: function (request, response) {
                $.ajax({
                    url: '/admin/shop_items/category_autocomplete',
                    dataType: 'json',
                    data: {
                        term: request.term
                    },
                    success: function (data) {
                        response(data);
                    }
                });
            },
            minLength: 2,
            select: function (event, ui) {
                $selectInput.val(ui.item.id);
                $searchInput.val(ui.item.label);
                return false;
            },
            focus: function (event, ui) {
                $searchInput.val(ui.item.label);
                return false;
            }
        });
    }
}

//Removed in commit "Use ShopItemType" 5th of September 2025
function createCategoryDropdowns() {
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
    categorySelect.change(function () {
        initialSubCategoryValue = null; // Clear initial value after first change
        updateSubCategories();
    });
}


$(document).ready(function () {
    initializeBestInPlace();
    initializeCategorySearchAutocomplete();
    //createCategoryDropdowns();
});