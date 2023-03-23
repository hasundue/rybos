module.exports = grammar({
  name: 'rybos',

  rules: {
    source_file: $ => repeat($._expression),

    _expression: $ => choice(
      $.identifier,
      $._binary_expression,
      $._number,
    ),

    identifier: $ => /[a-zA-Z_]+/,

    _number: $ => choice(
      $.integer,
      $.float,
    ),

    integer: $ => /[0-9]+/,
    float: $ => /[0-9]+\.[0-9]+/,

    _binary_expression: $ => choice(
      $.addition,
      $.substraction,
      $.multiplication,
      $.division,
    ),

    addition: $ => prec.left(1, seq($._expression, '+', $._expression)),
    substraction: $ => prec.left(1, seq($._expression, '-', $._expression)),
    multiplication: $ => prec.left(2, seq($._expression, '*', $._expression)),
    division: $ => prec.left(2, seq($._expression, '/', $._expression)),
  },
});
