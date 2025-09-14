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

function restoreSelectedItems() {
    // Get stored selected items from the server via AJAX
    $.ajax({
        url: '/admin/shop_items/get_stored_selected_items',
        method: 'GET',
        dataType: 'json',
        success: function (data) {
            if (data.selected_items && data.selected_items.length > 0) {
                console.log('Restoring selected items:', data.selected_items);

                // Restore selections
                data.selected_items.forEach(function (id) {
                    var checkbox = $('input[type="checkbox"][value="' + id + '"]');
                    if (checkbox.length > 0) {
                        checkbox.prop('checked', true);
                    }
                });

                // Update the batch action selector state
                updateBatchActionSelector();

                // Clear stored items from session
                $.ajax({
                    url: '/admin/shop_items/clear_stored_selected_items',
                    method: 'POST',
                    headers: {
                        'X-CSRF-Token': $('meta[name="csrf-token"]').attr('content')
                    }
                });
            }
        },
        error: function (xhr, status, error) {
            console.log('Error restoring selected items:', error);
        }
    });
}

function updateBatchActionSelector() {
    var paginated_collection_selector = 'collection_selection_toggle_all';
    // Trigger change event to update batch actions dropdown
    var checkedBoxes = $('.paginated_collection input[type="checkbox"][id="' + paginated_collection_selector + '"]');
    if (checkedBoxes.length > 0) {
        checkedBoxes.prop('checked', true);
    }

    var batch_action_selector = '.batch_actions_selector a.dropdown_menu_button';
    // remove thge displaed class from this element
    var batchActionButton = $(batch_action_selector);
    if (batchActionButton.length > 0) {
        batchActionButton.removeClass('disabled');
    }
}

function initializeActionLinks() {
    // Handle Calculate Price AJAX with direct event handling
    $('.calculate-price-link').on('click', function (e) {
        var $link = $(this);
        var shopItemId = $link.data('shop-item-id');

        // Don't prevent default - let Rails UJS handle the request

        // Listen for the response on the document
        $(document).one('ajax:success', '.calculate-price-link', function (event, data) {
            handleCalculatePriceSuccess(data, shopItemId);
        });

        $(document).one('ajax:error', '.calculate-price-link', function (event, xhr) {
            showNotification('error', 'An error occurred while calculating price');
        });
    });

    // Handle Re-assign Category AJAX with direct event handling
    $('.reassign-category-link').on('click', function (e) {
        var $link = $(this);
        var shopItemId = $link.data('shop-item-id');

        // Don't prevent default - let Rails UJS handle the request

        // Listen for the response on the document
        $(document).one('ajax:success', '.reassign-category-link', function (event, data) {
            handleReassignCategorySuccess(data, shopItemId);
        });

        $(document).one('ajax:error', '.reassign-category-link', function (event, xhr) {
            showNotification('error', 'An error occurred while reassigning category');
        });
    });

    // Handle Re-assign Unit Size AJAX with direct event handling
    $('.reassign-unit-size-link').on('click', function (e) {
        var $link = $(this);
        var shopItemId = $link.data('shop-item-id');

        // Don't prevent default - let Rails UJS handle the request

        // Listen for the response on the document
        $(document).one('ajax:success', '.reassign-unit-size-link', function (event, data) {
            handleReassignUnitSizeSuccess(data, shopItemId);
        });

        $(document).one('ajax:error', '.reassign-unit-size-link', function (event, xhr) {
            showNotification('error', 'An error occurred while reassigning unit & size');
        });
    });
}

function handleCalculatePriceSuccess(data, shopItemId) {
    if (data.status === 'success') {
        // Find the row by shop item ID
        var $titleLink = $('a[data-shop-item-id="' + shopItemId + '"]');
        var $row = $titleLink.closest('tr');

        // Update the latest_price_per_unified_unit column (column index 6)
        // instead of the index find prioceCell by class 'col-latest_price_per_unified_unit'
        var $priceCell = $row.find('td.col-latest_price_per_unified_unit')

        if (data.latest_price_per_unified_unit && data.latest_price_per_unified_unit !== 'N/A') {
            $priceCell.html(data.latest_price_per_unified_unit);
            $priceCell.find('span[style*="color: red"]').remove();
        }

        // Show success notification
        showNotification('success', data.message);

        // Add visual feedback
        $row.addClass('success-highlight');
        setTimeout(function () {
            $row.removeClass('success-highlight');
        }, 3000);
    } else {
        showNotification('error', data.message);
    }
}

function handleReassignCategorySuccess(data, shopItemId) {
    if (data.status === 'success') {
        // Find the row by shop item ID
        var $titleLink = $('a[data-shop-item-id="' + shopItemId + '"]');
        var $row = $titleLink.closest('tr');

        // Update the category column
        var $categoryCell = $row.find('td').has('.bip-select-unit[data-bip-attribute="category_id"]');

        if ($categoryCell.length === 0) {
            // Fallback: try to find by column index
            $categoryCell = $row.find('td').eq(8);
        }

        // Update the best_in_place element
        var $bipElement = $categoryCell.find('.bip-select-unit');
        if ($bipElement.length > 0) {
            $bipElement.attr('data-bip-value', data.category_id);
            $bipElement.text(data.category_breadcrumb);
            $bipElement.trigger('best_in_place:update');
        }

        // Show success notification
        showNotification('success', data.message);

        // Add visual feedback
        $row.addClass('success-highlight');
        setTimeout(function () {
            $row.removeClass('success-highlight');
        }, 3000);
    } else {
        showNotification('error', data.message);
    }
}

function handleReassignUnitSizeSuccess(data, shopItemId) {
    if (data.status === 'success') {
        // Find the row by shop item ID
        var $titleLink = $('a[data-shop-item-id="' + shopItemId + '"]');
        var $row = $titleLink.closest('tr');

        var $unitCell = $row.find('td.col-unit span')
        if (data.unit && data.unit !== 'N/A') {
            $unitCell.html(data.unit);
        }

        var $sizeCell = $row.find('td.col-size')
        if (data.size && data.size !== 'N/A') {
            $sizeCell.html(data.size);
        }

        // Show success notification
        showNotification('success', data.message);

        // Add visual feedback
        $row.addClass('success-highlight');
        setTimeout(function () {
            $row.removeClass('success-highlight');
        }, 3000);
    } else {
        showNotification('error', data.message);
    }
}

function showNotification(type, message) {
    // Remove existing notifications
    $('.ajax-notification').remove();

    // Create notification element
    var $notification = $('<div class="ajax-notification ajax-notification-' + type + '">' +
        '<span>' + message + '</span>' +
        '<button class="ajax-notification-close">&times;</button>' +
        '</div>');

    // Add to page
    $('body').prepend($notification);

    // Auto-remove after 5 seconds
    setTimeout(function () {
        $notification.fadeOut(function () {
            $notification.remove();
        });
    }, 5000);

    // Manual close
    $notification.find('.ajax-notification-close').on('click', function () {
        $notification.fadeOut(function () {
            $notification.remove();
        });
    });
}


$(document).ready(function () {
    initializeBestInPlace();
    initializeCategorySearchAutocomplete();
    initializeActionLinks();

    //createCategoryDropdowns();

    // Restore selections after page load
    setTimeout(function () {
        restoreSelectedItems();
    }, 500);
});