{{ config(tags=['unit-test', 'macro_test', 'postgres']) }}

{% call dbt_unit_testing.macro_test('sanitize None raises exception') %}
    {# TODO: How can we test expecting macro to raise exception? 
     # being able to do something like this would be great:
     #
     # {% call(msg) dbt_unit_testing.assert_raises_compiler_error() %}
     #     {{ dbt_unit_testing.sanitize(None) }}
     # {% endcall %} #}
{% endcall %}

UNION ALL

{% call dbt_unit_testing.macro_test('sanitize empty string returns empty string') %}
    {{ dbt_unit_testing.assert_equal(dbt_unit_testing.sanitize(''), '') }}
{% endcall %}

UNION ALL

{% call dbt_unit_testing.macro_test('sanitize unusual whitespace is replaced by single spaces') %}
    {{ dbt_unit_testing.assert_equal(
        dbt_unit_testing.sanitize('abc d  e\t\tgh\n\t\n ij\rk\fl\vm\u2005n\u2007o'),
        'abc d e gh ij k l m n o') }}
{% endcall %}

UNION ALL

{% call dbt_unit_testing.macro_test('sanitize whitespace at the ends is trimmed') %}
    {{ dbt_unit_testing.assert_equal(
        dbt_unit_testing.sanitize('\t \nfoo\v\r\f '), 'foo') }}
{% endcall %}


{# The tests below explore multiple ways that mocking could be implemented. #}

UNION ALL

{% call dbt_unit_testing.macro_test('example A: create mocks and remember to clean up at the end') %}
    {% set m = dbt_unit_testing.mock_macro(dbt_unit_testing, 'sanitize', mock_fn = mock_sanitize) %}
    {{ dbt_unit_testing.assert_equal(
        dbt_unit_testing.mock_example('foo'), 'x') }}
    {% do m.restore() %}
{% endcall %}

UNION ALL

{% call dbt_unit_testing.macro_test('example B: pass mock config in options, test runner cleans up', options={
    'mocks': [
        (dbt_unit_testing, 'sanitize', mock_sanitize),
    ]}) %}
    
    {{ dbt_unit_testing.assert_equal(
        dbt_unit_testing.mock_example('foo'), 'x') }}
{% endcall %}

UNION ALL

{% call dbt_unit_testing.macro_test('example C: mock using return_value') %}
    {% set m = dbt_unit_testing.mock_macro(dbt_unit_testing, 'sanitize', return_value=' happy ') %}
    
    {{ dbt_unit_testing.assert_equal(
        dbt_unit_testing.mock_example('foo'), ' happy ') }}

    {{ print('Mock called: %s' % m.calls) }} 
    {% do m.restore() %}
{% endcall %}

UNION ALL

{% call dbt_unit_testing.macro_test('example C.2: return_value can be something other than string') %}
    {% set m = dbt_unit_testing.mock_macro(dbt_unit_testing, 'sanitize', return_value=[1, 2]) %}
    
    {{ dbt_unit_testing.assert_equal(
        dbt_unit_testing.mock_example('foo'), [1, 2]) }}

    {% do m.restore() %}
{% endcall %}

UNION ALL

{% call(t) dbt_unit_testing.macro_test_with_t('example D: using t helper, test runner cleans up') %}
    {% do t.mock(dbt_unit_testing, 'sanitize', return_value='ttest') %}
    {{ t.assert_equal(
        dbt_unit_testing.mock_example('foo'), 'ttest') }}
{% endcall %}

UNION ALL

{% call(t) dbt_unit_testing.macro_test_with_t('example E: using t helper, mock using call') %}
    {% call(s) t.mock(dbt_unit_testing, 'sanitize') -%}
        {%- do print('sanitize called with %s' % (s|trim)) -%}
        {{ return({'mock_dict': 42}) }}
    {%- endcall %}
    {{ dbt_unit_testing.assert_equal(
        dbt_unit_testing.mock_example('foo'), {'mock_dict': 42}) }}
{% endcall %}

UNION ALL

{% call dbt_unit_testing.macro_test('check that all other tests restored mocks') %}
    {{ dbt_unit_testing.assert_equal(
        dbt_unit_testing.mock_example('abc'), 'abc') }}
{% endcall %}
