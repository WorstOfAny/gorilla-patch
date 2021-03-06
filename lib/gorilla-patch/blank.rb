# frozen_string_literal: true

require_relative 'deep_dup'

module GorillaPatch
	## Adding blank methods
	module Blank
		refine String do
			def blank?
				strip.empty?
			end
		end

		refine NilClass do
			def blank?
				true
			end
		end

		# rubocop:disable Metrics/BlockLength
		[Array, Hash].each do |klass|
			refine klass do
				def reject_blank_strings!
					replace reject_blank_strings
				end

				def nilify_blank_strings
					result = map do |element|
						if element.is_a?(String) && element.blank?
							nil
						elsif element.is_a?(Enumerable)
							element.nilify_blank_strings
						else
							element
						end
					end
					is_a?(Hash) ? result.to_h : result
				end

				def nilify_blank_strings!
					replace nilify_blank_strings
				end

				private

				def deep_value_empty?(value)
					deep_reject_blank_strings_in(value).empty?
				rescue NoMethodError
					false
				end

				def deep_reject_blank_strings_in(object)
					case object
					when String
						object.strip
					when Hash, Array
						object.reject_blank_strings!
					else
						object
					end
				end
			end
		end
		# rubocop:enable Metrics/BlockLength

		refine Array do
			using GorillaPatch::DeepDup

			def reject_blank_strings
				deep_dup.reject do |value|
					deep_value_empty? value
				end
			end
		end

		refine Hash do
			using GorillaPatch::DeepDup

			def reject_blank_strings
				deep_dup.reject do |_key, value|
					deep_value_empty? value
				end
			end
		end
	end
end
