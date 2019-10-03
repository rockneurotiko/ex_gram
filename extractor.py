#!/usr/bin/env python3

from bs4 import BeautifulSoup
import requests

DEBUG = False


def debug(t):
    if DEBUG:
        print("\n# " + t)

def arg_to_s(arg):
    return "{%s, [%s]%s}" % (arg[0], ", ".join(arg[1]), ", :optional" if arg[2] else "")

def build_method(name, args, returned):
    typ = ":get" if name.startswith("get") else ":post"

    if args is None:
        args = []

    args = [arg_to_s(x) for x in args]

    return """method {}, "{}", [{}], {}""".format(typ, name, ", ".join(args), returned)


def parse_types(text):
    res = []
    for t in text.split(" or "):
        t = t.strip()
        name = ""
        if t == "Integer":
            name = ":integer"
        elif t == "String":
            name = ":string"
        elif t == "Boolean":
            name = ":boolean"
        elif t == "Float":
            name = ":float"
        elif t == "True":
            name = ":boolean"
        elif t == "Float number":
            name = ":float"
        elif t == "InputFile":
            name = ":file"
        elif t.startswith("Array"):
            rest_t = " of ".join(t.split(" of ")[1:])
            more = parse_types(rest_t)
            el = more[0] if len(more) > 0 else ":any"
            name = "{:array, %s}" % el
        elif " and " in t:
            splitted = t.split(" and ")
            left = parse_types(splitted[0])[0]
            right = parse_types(" and ".join(splitted[1:]))[0]
            name = "[%s, %s]" % (left, right)
        elif t[0].isupper():
            name = t
            # debug("Class {} as any".format(t))
            # return [":any"]

        if name != "":
            res.append(name)
        else:
            debug("ERROR PARSING TYPE: {}".format(t))

    return res


def extract_table(table):
    res = []
    x = (len(table.findAll('tr')))

    for row in table.findAll("tr")[1:x]:
        col = row.findAll('td')
        name = col[0].getText()
        types = parse_types(col[1].getText())
        opt = col[2].getText() == "Optional"
        res.append((name, types, opt))

    return res


def good_type(t):
    t = t.strip(".").strip(",").strip()
    tl = t.lower()
    if tl == "exgram.model.int":
        return ":integer"

    if tl == "exgram.model.string":
        return ":string"

    if tl == "exgram.model.true":
        return ":true"

    return t

def extract_return_type(text):
    if "Array of Update objects is returned" in text:
      return "[ExGram.Model.Update]"

    tf = [" object is returned", " with the final results is returned", " is returned"]
    for x in tf:
      if x in text:
        return "ExGram.Model." + text.split(x)[0].split()[-1]

    if "returns an Array of GameHighScore" in text:
        return "[ExGram.Model.GameHighScore]"
    if "returns an Array of ChatMember" in text:
        return "[ExGram.Model.ChatMember]"

    ts = ["Returns basic information about the bot in form of a ",
          "returns the edited ",
          "Returns exported invite link as ",
          "Returns the new invite link as",
          "Returns the uploaded ",
          "Returns a ",
          "returns a ",
          "Returns ",
          "returns ",
          "On success, the stopped "]
    for x in ts:
        if x in text:
            return "ExGram.Model." + text.split(x)[1].split()[0]

    return ":any"
    # x is returned


def struct_t(name, types, opt):
    t = ":any" if len(types) == 0 else types[0]
    # t = t + ".t" if t[0].isupper() and t != "String" else t
    extra = "" if not opt else ", :optional"
    return "{:%s, %s%s}" % (name, t, extra)


def extract_model(h4):
    name = h4.text
    debug("Extracting type: " + name)
    table = h4.find_next("table")
    tabled = extract_table(table)
    model_s = "model {}, [{}]"

    ts = [struct_t(type_name, types, opt) for (type_name, types, opt) in tabled]
    debug(str(ts))
    return  model_s.format(name, ", ".join(ts))


def generic_to_text(name, sub_types):
    types_s = ", ".join(sub_types)
    types_t = " | ".join(["{}.t()".format(x) for x in sub_types])
    return """  defmodule {} do
    @type t :: {}

    def decode_as(), do: %{{}}

    def subtypes() do
      [{}]
    end
  end""".format(name, types_t, types_s)


def extract_generic(h4):
    name = h4.text
    debug("Extracting generic: " + name)
    l = h4.find_next("ul")
    sub_types = [li.text for li in l.findChildren("li", recursive=False)]

    return generic_to_text(name, sub_types)

def main():
    html = requests.get("https://core.telegram.org/bots/api").content

    soup = BeautifulSoup(html, 'html.parser')

    n = 0

    # updates = soup.find(href="#getting-updates").parent.findAllNext("h4")

    h4s = soup.find(href="#getting-updates").parent.findAllNext("h4")


    # h4s = soup.find(href="#available-methods").parent.findAllNext("h4")

    skip = []
    generic_types = ["InlineQueryResult", "InputMessageContent", "PassportElementError"]
    not_parameters = ["getMe", "deleteWebhook", "getWebhookInfo"]

    models = []
    methods = []
    generics = []

    for h4 in h4s:
        name = h4.text

        if name in skip:
            debug("Skipping {}".format(name))
            continue

        if name in generic_types:
            generics.append(extract_generic(h4))
            continue
        if name[0].isupper():
            if len(name.split(" ")) == 1:
                models.append(extract_model(h4))
            continue

        debug(name)
        n += 1

        returned = good_type(extract_return_type(h4.find_next("p").text))
        debug("RETURNS: " + returned)

        if name in not_parameters:
            methods.append(build_method(name, [], returned))
            continue

        table = h4.find_next("table")
        tabled = extract_table(table)

        methods.append(build_method(name, tabled, returned))


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
