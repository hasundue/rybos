module.exports = grammar({
  name: 'rybos',

  rules: {
    source_file: $ => repeat($._expression),

    _expression: $ => choice(
      $.identifier,
      $._number,
      $.binary_expression,
    ),

    identifier: $ => /[a-zA-Z_]+/,

    _number: $ => choice(
      $.integer,
      $.float,
    ),

    integer: $ => /[0-9]+/,

    float: $ => /[0-9]+\.[0-9]+/,

    binary_expression: $ => choice(
      $._binary_operator_prior,
      $._binary_operator_post,
    ),

    _binary_operator_prior: $ => choice(
      '*',
      '/',
    ),

    _binary_expression_prior: $ => choice(
      prec.left(2, seq($._expression, $._binary_operator_prior, $._expression)),
    ),

    _binary_operator_post: $ => choice(
      '+',
      '-',
    ),

    _binary_expression_post: $ => choice(
      prec.left(1, seq($._expression, $._binary_operator_post, $._expression)),
    ),
  },
});
