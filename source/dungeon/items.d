module dungeon.items;
import dungeon.state;

const Item[] weapons = [
    Item("Branch", 1),
    Item("Short Sword", 6),
    Item("Knife", 3),
];

const Item[] potions = [
    Item("Healing Potion", -25),
];

const Enemy[] enemies = [
    Enemy("Dungeon Bat", 5, Item("Teeth", 1), 'M'),
    Enemy("Dungeon Crawler", 25, Item("Metal Teeth", 3), '&'),
];
