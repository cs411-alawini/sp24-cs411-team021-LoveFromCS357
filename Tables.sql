DROP TABLE IF EXISTS UserLikeRecipe;
DROP TABLE IF EXISTS UserRatesRecipe;
DROP TABLE IF EXISTS RecipeIncludesIngredients;
DROP TABLE IF EXISTS MarketsSellsIngredients;

DROP TABLE IF EXISTS Nutrition;
DROP TABLE IF EXISTS Recipes;
DROP TABLE IF EXISTS Users;
DROP TABLE IF EXISTS Ingredients;
DROP TABLE IF EXISTS Markets;

CREATE TABLE Users (
    user_id         INT NOT NULL,
    user_email      VARCHAR(255) NOT NULL UNIQUE,
    user_name       VARCHAR(255) NOT NULL,
    password        VARCHAR(100) NOT NULL,

    PRIMARY KEY (user_id)
);

CREATE TABLE Recipes (
    recipe_id       INT NOT NULL,
    recipe_name     VARCHAR(255) NOT NULL,
    recipe_type     VARCHAR(255),
    user_email      VARCHAR(255) NOT NULL UNIQUE,

    PRIMARY KEY (recipe_id),
    FOREIGN KEY (user_email) REFERENCES Users(user_email) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE Ingredients (
    ingredient_id   INT NOT NULL,
    ingredient_name VARCHAR(255) NOT NULL UNIQUE,
    ingredient_type VARCHAR(255),

    PRIMARY KEY (ingredient_id)
);

CREATE TABLE Nutrition (
    recipe_id       INT NOT NULL,
    calorie         DECIMAL(10, 2),
    carbon_hydrate  INT,
    fat             DECIMAL(10, 2),

    PRIMARY KEY (recipe_id),
    FOREIGN KEY (recipe_id) REFERENCES Recipes(recipe_id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE Markets (
    market_id           INT NOT NULL,
    market_name         VARCHAR(255) NOT NULL,
    market_location     VARCHAR(255) NOT NULL,

    PRIMARY KEY (market_id)
);

CREATE TABLE UserLikeRecipe (
    user_id         INT NOT NULL,
    recipe_id       INT NOT NULL,

    PRIMARY KEY (user_id, recipe_id),
    FOREIGN KEY (user_id) REFERENCES Users(user_id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (recipe_id) REFERENCES Recipes(recipe_id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE UserRatesRecipe (
    user_id         INT NOT NULL,
    recipe_id       INT NOT NULL,
    rating          INT NOT NULL,
    comment         VARCHAR(255),

    PRIMARY KEY (user_id, recipe_id),
    FOREIGN KEY (user_id) REFERENCES Users(user_id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (recipe_id) REFERENCES Recipes(recipe_id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE RecipeIncludesIngredients (
    recipe_id           INT NOT NULL,
    ingredient_id       INT NOT NULL,

    PRIMARY KEY (recipe_id, ingredient_id),
    FOREIGN KEY (recipe_id) REFERENCES Recipes(recipe_id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (ingredient_id) REFERENCES Ingredients(ingredient_id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE MarketsSellsIngredients (
    market_id           INT NOT NULL,
    ingredient_id       INT NOT NULL,

    PRIMARY KEY (market_id, ingredient_id),
    FOREIGN KEY (market_id) REFERENCES Markets(market_id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (ingredient_id) REFERENCES Ingredients(ingredient_id) ON DELETE CASCADE ON UPDATE CASCADE
);
