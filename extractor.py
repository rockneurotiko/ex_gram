#!/usr/bin/env python3

import requests

DEBUG = True
# URL = "https://raw.githubusercontent.com/rockneurotiko/telegram_api_json/master/exports/tg_api.json"
URL = "https://raw.githack.com/rockneurotiko/telegram_api_json/master/exports/tg_api_pretty.json"


def debug(t):
    if DEBUG:
        print("\n# " + t)


def maybe_atom(name, is_return):
    return ":{}".format(name) if not is_return else name


def parse_type_name(name, is_return):
    if name == "int":
        return maybe_atom("integer", is_return)
    if name == "str":
        return "String" if is_return else ":string"
    if name == "bool":
        return maybe_atom("boolean", is_return)
    if name == "float":
        return maybe_atom("float", is_return)
    if name == "file":
        return maybe_atom("file", is_return)
    if name == "True" or name == "true":
        return "true"
    if name == "String":
        return "String"
    if name[0].isupper():
        return "ExGram.Model.{}".format(name) if is_return else name

    if name[0] == "array":
        ts = [parse_type_name(x, is_return) for x in name[1]]
        t = ts[0] if len(ts) == 1 else "[{}]".format(", ".join(ts))
        return "{{:array, {}}}".format(t)

    return ":any"


def generate_type(typ, is_return):
    if len(typ) == 0:
        return [":any"]

    if len(typ) == 1:
        return [parse_type_name(typ[0], is_return)]

    if typ[0] == "array":
        array_type = parse_type_name(typ[1][0], is_return)
        return ["[{}]".format(array_type)]

    return [parse_type_name(x, is_return) for x in typ]


def generate_param(param, model):
    param_s = "{{{}, {}{}}}"

    name = ":{}".format(param['name']) if model else param['name']
    debug("Extracting type: " + name)
    ts = generate_type(param['type'], False)
    t = ts[0] if model else "[{}]".format(', '.join(ts))
    debug(str(t))
    extra = "" if not param['optional'] else ", :optional"

    return param_s.format(name, t, extra)


def generate_model(model):
    model_s = "model {}, [{}]"
    name = model['name']
    debug("Generating model: " + name)
    params = [generate_param(param, True) for param in model['params']]

    return model_s.format(name, ", ".join(params))


def generate_method(method):
    method_s = """method {}, "{}", [{}], {}"""
    name = method['name']
    debug("Generating method: " + name)
    typ = ":get" if method['type'] == 'get' else ':post'

    args = [generate_param(param, False) for param in method['params']]
    returned = generate_type(method['return'], True)[0]

    return method_s.format(typ, name, ", ".join(args), returned)


def generate_generic(model):
    name = model['name']
    types_s = ", ".join(model['subtypes'])
    types_t = " | ".join(["{}.t()".format(x) for x in model['subtypes']])
    return """defmodule {} do
  @type t :: {}

  def subtypes() do
    [{}]
  end
    end""".format(name, types_t, types_s)


def main():
    definition = requests.get(URL).json()

    models = [generate_model(model) for model in definition['models']]
    methods = [generate_method(method) for method in definition['methods']]
    generics = [generate_generic(generic) for generic in definition['generics']]

    debug("----------METHODS-----------\n")
    print("# AUTO GENERATED")
    print()
    print("# Methods")
    print()
    print("\n\n".join(methods))
    debug("{} methods\n".format(len(methods)))

    debug("----------MODELS-----------\n")
    print("# Models")
    print()
    print("\ndefmodule Model do")
    print("\n\n  ".join(models))
    debug("{} models\n".format(len(models)))
    print("\n\n ".join(generics))
    debug("{} generics\n".format(len(generics)))
    print("end")


if __name__ == "__main__":
    main()
