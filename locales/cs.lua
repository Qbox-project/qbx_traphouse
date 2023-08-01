local Translations = {
    error = {
        not_enough = "Nemáš dostatek peněz..",
        no_slots = "Není zde volné volné místo",
        occured = "Vyskytla se chyba",
        have_keys = "Tato osoba už má klíče",
        p_have_keys = "%{value} už má klíče",
        not_owner = "Nevlastníš žádny traphouse nebo nejsi majitelem",
        not_online = "Osoba není ve městě",
        no_money = "Ve skříni nejsou žádné peníze",
        incorrect_code = "Kód je nesprávný",
        up_to_6 = "Do domu s pastmi můžete dát přístup až 6 lidem!",
        cancelled = "Zrušené akvizice",
    },
    success = {
        added = "%{value} Byl přidán do Traphousu",
    },
    info = {
        enter = "Vstoupit do Traphousu",
        give_keys = "Půjčit klíče od Traphousu",
        pincode = "Traphouse Pincode: %{value}",
        taking_over = "Přebíraní",
        pin_code_see = "~b~G~w~ - Podívat se na pinkód",
        pin_code = "Pinkód: %{value}",
        multikeys = "~b~/multikeys~w~ [id] - Půjčit klíče",
        take_cash = "~b~E~w~ - Vzít peníze (~g~$%{value}~w~)",
        inventory = "~b~H~w~ - Zobrazit inventář",
        take_over = "~b~E~w~ - Převzít (~g~$5000~w~)",
        leave = "~b~E~w~ - Opustit Traphouse",
    },
    targetInfo = {
        options = "Traphouse Nastavení",
        enter = "Vstoupit do Traphousu",
        give_keys = "Půjčit klíče od Traphousu",
        pincode = "Traphouse Pinkód: %{value}",
        taking_over = "Přebírání",
        pin_code_see = "Podívat se na  pinkód",
        pin_code = "Pinkód: %{value}",
        multikeys = "Půjčit klíče (použij /multikey [id])",
        take_cash = "Vzít peníze ($%{value})",
        inventory = "Zobrazit inventář",
        take_over = "Převzít ($5000)",
        leave = "Opustit Traphouse",
        close_menu = "⬅ Zavřit Menu",
    }
}

if GetConvar('qb_locale', 'en') == 'cs' then
    Lang = Locale:new({
        phrases = Translations,
        warnOnMissing = true,
        fallbackLang = Lang,
    })
end