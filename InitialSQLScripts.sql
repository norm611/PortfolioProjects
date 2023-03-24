Select location, continent, date,total_cases, total_deaths 
from CovidDeaths$
WHERE continent IS NOT NULL AND continent like 'North%' and (location = 'Canada' or location like '%states%')
ORDER BY total_deaths desc

SELECT location,continent, date,total_cases, new_cases, total_deaths, population
FROM CovidDeaths$

ORDER BY 1,2 


--Looking at Total_cases vs Total_deaths
-- -- total_cases and total_deaths are int.  They need to be CAST as float to get a decimal result
-- -- Likelihood of dying from covid if contracted in country

SELECT location, date,total_cases, total_deaths,  (CAST (total_deaths as float)/cast(total_cases as float)) *100 AS DeathPercentage
FROM CovidDeaths$
where location = 'Canada' AND continent IS NOT NULL
ORDER BY 1,2


-- Looking at Total cases Vs Population
SELECT location, date,total_cases, total_deaths, population,  (CAST (total_deaths as float)/cast(population as float)) *100 AS DeathPerPopulation
FROM CovidDeaths$
where location = 'Canada' AND continent IS NOT NULL
ORDER BY 1,2

SELECT location, date,total_cases, total_deaths, population,  (CAST (total_cases as float)/cast(population as float)) *100 AS CasesPerPopulation
FROM CovidDeaths$
where location = 'Canada' AND continent IS NOT NULL
ORDER BY 1,2



-- What countries have the highest infection rate compared to population
SELECT location,  population, MAX(total_cases) as HighestInfectionCount, MAX((CAST (total_cases as float)/cast(population as float)) *100 ) AS PercentagePopulationInfected 
FROM CovidDeaths$
WHERE continent IS NOT NULL
GROUP BY location,  population
ORDER BY PercentagePopulationInfected desc


-- Show Countries with Highest Death Count per Population
SELECT location,  population , MAX(total_deaths) as HighestDeathCount, MAX((CAST (total_deaths as float)/cast(population as float)) *100) AS HighestDeathsPerPopulation 
FROM CovidDeaths$
WHERE continent IS NOT NULL
GROUP BY location,  population
ORDER BY  HighestDeathsPerPopulation  desc


-- Show Countries with the highest number of deaths by Covid
SELECT location,  population , MAX(total_deaths) as HighestDeathCount
FROM CovidDeaths$
WHERE continent IS NOT NULL
GROUP BY location,  population
ORDER BY  HighestDeathCount  desc


-- Show the one country with the max total deaths Deaths on a  Continent, ie Unites States for North America, etc
-- This is deceiving because it looks like All of continent is that Count
SELECT continent , MAX(total_deaths) as HighestDeathCountOfACountry
FROM CovidDeaths$
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY  HighestDeathCountOfACountry  desc











-- Death 
SELECT CountryDeaths.continent,  SUM (CountryDeaths.HighestDeathCount) AS ContinentDeathCount
FROM (
	SELECT location,continent , MAX(total_deaths) as HighestDeathCount
	FROM CovidDeaths$
	WHERE continent IS NOT NULL
	GROUP BY continent, location
	) AS CountryDeaths
GROUP BY CountryDeaths.continent



-- Show highest Death Counts included in Data by location, this includes High Income, Upper Middle Income, etc

SELECT location , MAX(total_deaths) as HighestDeathCount
FROM CovidDeaths$
WHERE continent IS NULL
GROUP BY location
ORDER BY  HighestDeathCount  desc


-- Show Highest Death Count of Countries in NorhtAmerica
Select location, continent, MAX(total_deaths) as HighestDeathCount 
from CovidDeaths$
WHERE continent IS NOT NULL AND continent like 'North%'
GROUP BY location, continent
ORDER BY HighestDeathCount desc


-- Global numbers per day
SELECT  date,SUM(new_cases) AS total_cases, SUM(new_deaths) AS total_deaths, SUM(CAST (new_deaths as float))/SUM(cast(new_cases as float)) *100 AS DeathPercentage
FROM CovidDeaths$
where new_cases > 0
GROUP BY date
ORDER BY 1,2

-- Global numbers 
SELECT  SUM(new_cases) AS total_cases, SUM(new_deaths) AS total_deaths, SUM(CAST (new_deaths as float))/SUM(cast(new_cases as float)) *100 AS DeathPercentage
FROM CovidDeaths$
where new_cases > 0

ORDER BY 1,2


-- Looking at total population VS Vaccination

Select deathtb.continent, deathtb.location, deathtb.date, deathtb.population, vactb.new_vaccinations
	, SUM( vactb.new_vaccinations) OVER (PARTITION BY deathtb.location ORDER BY deathtb.location, deathtb.date) AS RollingVaccinations
FROM CovidDeaths$ AS deathtb
JOIN CovidVaccinations$ AS vactb
	ON deathtb.location = vactb.location
	AND deathtb.date = vactb.date
WHERE deathtb.continent IS NOT NULL 
ORDER BY 2,3

-------------------------------------------------------------------
-- USE CTE
WITH PopVsVac (Continent, Location, Date, Population, New_Vaccinations, RollingVaccinated  )
AS 
(
	Select deathtb.continent, deathtb.location, deathtb.date, deathtb.population, vactb.new_vaccinations
		, SUM( vactb.new_vaccinations) OVER (PARTITION BY deathtb.location ORDER BY deathtb.location, deathtb.date) AS RollingVaccinations
	FROM CovidDeaths$ AS deathtb
	JOIN CovidVaccinations$ AS vactb
		ON deathtb.location = vactb.location
		AND deathtb.date = vactb.date
	WHERE deathtb.continent IS NOT NULL 
	--ORDER BY 2,3
)
SELECT *, (CAST(RollingVaccinated AS float) / CAST(Population AS float)) *100 AS PercentPopulationVaccinated
FROM PopVsVac
-----------------------------------------------------------------
--Use Temp TAble
DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
	Continent nvarchar(255),
	Location nvarchar(255),
	Date date,
	Population numeric,
	New_Vaccinations numeric,
	RollingVaccinations numeric
)

INSERT INTO #PercentPopulationVaccinated
	Select deathtb.continent, deathtb.location, deathtb.date, deathtb.population, vactb.new_vaccinations
		, SUM( vactb.new_vaccinations) OVER (PARTITION BY deathtb.location ORDER BY deathtb.location, deathtb.date) AS RollingVaccinations
	FROM CovidDeaths$ AS deathtb
	JOIN CovidVaccinations$ AS vactb
		ON deathtb.location = vactb.location
		AND deathtb.date = vactb.date
	WHERE deathtb.continent IS NOT NULL 
	ORDER BY 2,3 

SELECT *, (CAST(RollingVaccinations AS float) / CAST(Population AS float)) *100 AS PercentPopulationVaccinated
FROM #PercentPopulationVaccinated

-----------------------------------
-- Creating Views to store data for later visualizations
-----------------------------------
CREATE VIEW PercentPopulationVaccinated AS
	Select deathtb.continent, deathtb.location, deathtb.date, deathtb.population, vactb.new_vaccinations
		, SUM( vactb.new_vaccinations) OVER (PARTITION BY deathtb.location ORDER BY deathtb.location, deathtb.date) AS RollingVaccinations
	FROM CovidDeaths$ AS deathtb
	JOIN CovidVaccinations$ AS vactb
		ON deathtb.location = vactb.location
		AND deathtb.date = vactb.date
	WHERE deathtb.continent IS NOT NULL 


Select * 
FROM PercentPopulationVaccinated