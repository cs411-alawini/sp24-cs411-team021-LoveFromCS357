--Common Ingredients in Recipes Rated 2 or Higher with "Good" Comments
--JOIN and AGGREGATION
SELECT 
    Ingredients.ingredient_name,
    COUNT(Ingredients.ingredient_name) AS ingredient_count
FROM 
    Ingredients
JOIN 
    RecipeIncludesIngredients ON Ingredients.ingredient_id = RecipeIncludesIngredients.ingredient_id
JOIN 
    Recipes ON RecipeIncludesIngredients.recipe_id = Recipes.recipe_id
JOIN 
    UserRatesRecipe ON Recipes.recipe_id = UserRatesRecipe.recipe_id
WHERE 
    UserRatesRecipe.rating >= 2
    AND UserRatesRecipe.comment LIKE '%good%'
GROUP BY 
    Ingredients.ingredient_name
HAVING 
    COUNT(DISTINCT Recipes.recipe_id) > 1 -- Ensures the ingredient is common across multiple recipes
ORDER BY 
    ingredient_count DESC;



-- Find Users Who Like and Rate the Same Recipe
--JOIN, AGGREGATION
SELECT 
    Ingredients.ingredient_name,
    COUNT(*) AS popularity
FROM 
    Ingredients
JOIN 
    RecipeIncludesIngredients ON Ingredients.ingredient_id = RecipeIncludesIngredients.ingredient_id
JOIN 
    Recipes ON RecipeIncludesIngredients.recipe_id = Recipes.recipe_id
JOIN 
    UserLikeRecipe ON Recipes.recipe_id = UserLikeRecipe.recipe_id
WHERE 
    UserLikeRecipe.user_id > 2
    AND Recipes.recipe_name NOT LIKE '%shit%'
GROUP BY 
    Ingredients.ingredient_name
ORDER BY 
    popularity DESC
LIMIT 15;




--Average Rating for Ingredients in Popular Recipes, where nutrition has calories < 200 and fat < 20
--JOIN SET AGGREGATION
SELECT 
    Ingredients.ingredient_name,
    AVG(UserRatesRecipe.rating) AS average_rating
FROM 
    Ingredients
JOIN 
    RecipeIncludesIngredients ON Ingredients.ingredient_id = RecipeIncludesIngredients.ingredient_id
JOIN 
    Recipes ON RecipeIncludesIngredients.recipe_id = Recipes.recipe_id
JOIN 
    UserRatesRecipe ON Recipes.recipe_id = UserRatesRecipe.recipe_id
JOIN 
    Nutrition ON Recipes.recipe_id = Nutrition.recipe_id
WHERE 
    Recipes.recipe_id IN (
        SELECT 
            RecipeIncludesIngredients.recipe_id
        FROM 
            RecipeIncludesIngredients
        JOIN 
            UserLikeRecipe ON RecipeIncludesIngredients.recipe_id = UserLikeRecipe.recipe_id
        GROUP BY 
            RecipeIncludesIngredients.recipe_id
        HAVING 
            COUNT(UserLikeRecipe.user_id) > 10
    )
    AND Nutrition.calorie < 200
    AND Nutrition.fat < 20
GROUP BY 
    Ingredients.ingredient_name
ORDER BY 
    average_rating DESC;


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
    WHERE 
        UserRatesRecipe.comment NOT LIKE '%bad%'
    GROUP BY 
        RecipeIncludesIngredients.ingredient_id
    HAVING 
        AVG(UserRatesRecipe.rating) > 1
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
