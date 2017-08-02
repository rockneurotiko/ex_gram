from bs4 import BeautifulSoup
import requests

DEBUG = True


def debug(t):
    if DEBUG:
        print("# " + t)

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
            more = parse_types(t.split(" of ")[-1])
            el = more[0] if len(more) > 0 else ":any"
            name = "{:array, %s}" % el
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
    if t == "Telex.Model.Int":
        return "integer"

    if t == "Telex.Model.String":
        return "String.t"

    if t.lower() in ["telex.model.true"]:
        return "true"

    return t

def extract_return_type(text):
    if "Array of Update objects is returned" in text:
        return "[Telex.Model.Update]"
    if "File object is returned" in text:
        return "Telex.Model.File"
    if " is returned" in text:
        return "Telex.Model." + text.split(" is returned")[0].split()[-1]
    if "returns an Array of GameHighScore" in text:
        return "[Telex.Model.GameHighScore]"
    if "returns an Array of ChatMember" in text:
        return "[Telex.Model.ChatMember]"

    ts = ["Returns basic information about the bot in form of a ",
          "returns the edited ",
          "Returns a ",
          "returns a ",
          "Returns ",
          "returns "]
    for x in ts:
        if x in text:
            return "Telex.Model." + text.split(x)[1].split()[0]

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

    ts = [struct_t(name, types, opt) for (name, types, opt) in tabled]
    debug(str(ts))
    return  model_s.format(name, ", ".join(ts))

html = requests.get("https://core.telegram.org/bots/api").content

soup = BeautifulSoup(html, 'html.parser')

n = 0

# updates = soup.find(href="#getting-updates").parent.findAllNext("h4")

h4s = soup.find(href="#getting-updates").parent.findAllNext("h4")


# h4s = soup.find(href="#available-methods").parent.findAllNext("h4")

skip = ["InlineQueryResult", "InputMessageContent"]
not_parameters = ["getMe", "deleteWebhook", "getWebhookInfo"]

models = []
methods = []

for h4 in h4s:
    name = h4.text

    if name in skip:
        debug("Skipping {}".format(name))
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
print("\n\n".join(methods))
debug("{} methods".format(len(methods)))

debug("----------MODELS-----------\n")
print("\n\n".join(models))
debug("{} models".format(len(models)))
