--Find the Top 5 Most Liked Recipes
--JOIN and AGGREGATION
SELECT 
    Recipes.recipe_name,
    COUNT(UserLikeRecipe.recipe_id) AS like_count
FROM 
    Recipes
JOIN 
    UserLikeRecipe ON Recipes.recipe_id = UserLikeRecipe.recipe_id
GROUP BY 
    Recipes.recipe_name
ORDER BY 
    like_count DESC
LIMIT 5;


-- Find Users Who Like and Rate the Same Recipe
--JOIN, SET(IN)
SELECT 
    Users.user_name,
    Recipes.recipe_name,
    UserRatesRecipe.rating
FROM 
    Users
JOIN 
    UserLikeRecipe ON Users.user_id = UserLikeRecipe.user_id
JOIN 
    UserRatesRecipe ON Users.user_id = UserRatesRecipe.user_id
JOIN 
    Recipes ON UserLikeRecipe.recipe_id = Recipes.recipe_id
WHERE 
    Recipes.recipe_id IN (SELECT recipe_id FROM UserRatesRecipe)
GROUP BY 
    Users.user_name, Recipes.recipe_name, UserRatesRecipe.rating
HAVING 
    COUNT(DISTINCT Recipes.recipe_id) > 1;


--Compare Average Ratings of Recipes Containing 'Chicken' vs. 'Beef'
--JOIN SET AGGREGATION
SELECT 
    'Chicken' AS ingredient_type, 
    AVG(rating) AS avg_rating
FROM 
    UserRatesRecipe
WHERE 
    recipe_id IN (SELECT recipe_id FROM RecipeIncludesIngredients WHERE ingredient_id IN (SELECT ingredient_id FROM Ingredients WHERE ingredient_name LIKE '%chicken%'))
UNION
SELECT 
    'Beef' AS ingredient_type, 
    AVG(rating)
FROM 
    UserRatesRecipe
WHERE 
    recipe_id IN (SELECT recipe_id FROM RecipeIncludesIngredients WHERE ingredient_id IN (SELECT ingredient_id FROM Ingredients WHERE ingredient_name LIKE '%beef%'));


-- Identify Ingredients in High-rated Recipes and Available in Downtown Markets
--JOIN SET 
SELECT DISTINCT
    Ingredients.ingredient_name
FROM 
    Ingredients
JOIN (
    SELECT 
        RecipeIncludesIngredients.ingredient_id
    FROM 
        RecipeIncludesIngredients
    JOIN 
        UserRatesRecipe ON RecipeIncludesIngredients.recipe_id = UserRatesRecipe.recipe_id
    GROUP BY 
        RecipeIncludesIngredients.ingredient_id
    HAVING 
        AVG(UserRatesRecipe.rating) >= 4
) AS HighRatedIngredients ON Ingredients.ingredient_id = HighRatedIngredients.ingredient_id
JOIN (
    SELECT 
        MarketsSellsIngredients.ingredient_id
    FROM 
        MarketsSellsIngredients
    JOIN 
        Markets ON MarketsSellsIngredients.market_id = Markets.market_id
    WHERE 
        Markets.market_location LIKE '%GreenVille%'
) AS DowntownMarkets ON Ingredients.ingredient_id = DowntownMarkets.ingredient_id;
