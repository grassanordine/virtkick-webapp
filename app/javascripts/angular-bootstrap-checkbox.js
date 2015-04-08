//Wrapped in an outer function to preserve global this
(function (root) { var amdExports; define(['angular'], function (angular) { (function () {

"use strict";

angular.module("ui.checkbox", []).directive("checkbox", function() {
	return {
		scope: {
      disabled:'=ngDisabled'
    },
		require: "ngModel",
		restrict: "E",
		replace: "true",
		template: "<button type=\"button\" ngDisabled=\"disabled\" ng-style=\"stylebtn\" class=\"btn btn-default\" ng-class=\"{'btn-xs': size==='default', 'btn-sm': size==='large', 'btn-lg': size==='largest'}\">" +
			"<span ng-style=\"styleicon\" class=\"icon fa\" ng-class=\"{'fa-check': checked===true}\"></span>" +
			"</button>",
		link: function(scope, elem, attrs, modelCtrl) {
			scope.size = "default";
			// Default Button Styling
			scope.stylebtn = {};
			// Default Checkmark Styling
			scope.styleicon = {"width": "10px", "left": "0px"};
			// If size is undefined, Checkbox has normal size (Bootstrap 'xs')
			if(attrs.large !== undefined) {
				scope.size = "large";
				scope.stylebtn = {"padding-top": "2px", "padding-bottom": "2px", "height": "30px"};
				scope.styleicon = {"width": "8px", "left": "-7px", "font-size": "24px", position: 'relative'};
			}
			if(attrs.larger !== undefined) {
				scope.size = "larger";
				scope.stylebtn = {"padding-top": "2px", "padding-bottom": "2px", "height": "34px"};
				scope.styleicon = {"width": "8px", "left": "-8px", "font-size": "22px"};
			}
			if(attrs.largest !== undefined) {
				scope.size = "largest";
				scope.stylebtn = {"padding-top": "2px", "padding-bottom": "2px", "height": "45px"};
				scope.styleicon = {"width": "11px", "left": "-11px", "font-size": "30px"};
			}

			var trueValue = true;
			var falseValue = false;

			// If defined set true value
			if(attrs.ngTrueValue !== undefined) {
				trueValue = attrs.ngTrueValue;
			}
			// If defined set false value
			if(attrs.ngFalseValue !== undefined) {
				falseValue = attrs.ngFalseValue;
			}

			// Check if name attribute is set and if so add it to the DOM element
			if(scope.name !== undefined) {
				elem.name = scope.name;
			}

			// Update element when model changes
			scope.$watch(function() {
				if(modelCtrl.$modelValue === trueValue || modelCtrl.$modelValue === true) {
					modelCtrl.$setViewValue(trueValue);
				} else {
					modelCtrl.$setViewValue(falseValue);
				}
				return modelCtrl.$modelValue;
			}, function(newVal, oldVal) {
				scope.checked = modelCtrl.$modelValue === trueValue;
			}, true);

			// On click swap value and trigger onChange function
			elem.bind("click", function() {
				scope.$apply(function() {
					if(modelCtrl.$modelValue === falseValue) {
						modelCtrl.$setViewValue(trueValue);
					} else {
						modelCtrl.$setViewValue(falseValue);
					}
				});
			});
		}
	};
});

amdExports = 'ui.checkbox';
}.call(root));
    return amdExports;
}); }(this));
