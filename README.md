# JsonFinisher

![ci workflow](https://github.com/oshbec/json_finisher/actions/workflows/ci.yml/badge.svg)

Takes a truncated JSON string and "finishes" it.

You might be streaming a response back from an LLM formatted in JSON. If the content is in response to a user request, you'll probably want to show results as they're being generated, rather than making the user wait for the full response to complete. If the response is JSON formatted, you're dealing with truncated JSON until the response is complete. Just about all JSON parsers won't be able to handle this as input.

## Example

`JsonFinisher` will take valid json that just happens to be truncated at any arbitrary point, and finish it up so that you can pass it into the perser of your choice. Some examples:

| Truncated JSON    | Finished JSON        |
| ----------------- | -------------------- |
| `{`               | `{}`                 |
| `[`               | `[]`                 |
| `{"`              | `{"":null}`          |
| `{"a`             | `{"a": null}`        |
| `{"a": tr`        | `{"a": true}`        |
| `{"a": {"b": "hi` | `{"a": {"b": "hi"}}` |

## JSON Validity

The truncated JSON needs to be valid up until the point it was truncated. This thing will do what it can to finish a truncated string, but it's not going to magically fix something that's malformed. Consider its output undefined in that scenario.
