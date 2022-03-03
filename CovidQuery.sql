-- Query all data from CovidDeaths table
SELECT *
FROM [CovidProject]..CovidDeaths
ORDER BY location, date

-- Query all data from CovidVaccinations table
SELECT *
FROM [CovidProject]..CovidVaccinations
ORDER BY location, date

-- Select data we want to use
SELECT 
Location, 
date, 
total_cases, 
new_cases, 
total_deaths, 
population
FROM [CovidProject]..CovidDeaths
ORDER BY location, date

-- Let's look at Total Cases Vs Total Deaths
-- Calculating death percentage to show likelihood of dying if you contract COVID
SELECT 
Location, 
date, 
total_cases, 
new_cases, 
total_deaths, 
(total_deaths/total_cases)*100 as DeathPercentage
FROM [CovidProject]..CovidDeaths
WHERE Location like '%Canada%' OR Location like '%states%'
ORDER BY location, date

-- Investigating the total cases vs population 
-- Calculating percentage of population that got COVID
SELECT 
Location, 
date, 
total_cases, 
Population,
(total_cases/population)*100 as CovidPercentage
FROM [CovidProject]..CovidDeaths
WHERE Location like '%Canada%' OR Location like '%states%'
ORDER BY location, date

-- Looking at highest infection rate compared to population
SELECT 
Location, 
MAX(total_cases) as HighestInfectionCount, 
Population,
MAX((total_cases/population))*100 as CovidPercentage
FROM [CovidProject]..CovidDeaths
WHERE continent is not null --filter for countries to not include world areas
GROUP BY location, population
ORDER BY CovidPercentage desc

-- Show Death Count per population due to COVID
SELECT 
Location, 
MAX(CAST(total_deaths as int)) as TotalDeathCount,
population,
MAX((total_deaths/population))*100 as TotalDeathPercentage
FROM [CovidProject]..CovidDeaths
WHERE continent is not null --filter for only world category areas
GROUP BY location, population
ORDER BY TotalDeathCount desc 

-- Show continents with highest death count per population
SELECT 
location, 
MAX(CAST(total_deaths as int)) as TotalDeathCount
FROM [CovidProject]..CovidDeaths
WHERE continent is null
GROUP BY Location
ORDER BY TotalDeathCount desc 

-- Total population vs vaccinations
SELECT 
deaths.continent, 
deaths.location, 
deaths.date, 
deaths.population, 
vaccs.new_vaccinations,
SUM(CONVERT(bigint, vaccs.new_vaccinations)) OVER (PARTITION BY deaths.location ORDER BY deaths.location, deaths.date) as rolling_total_vaccinations
FROM [CovidProject]..CovidDeaths deaths
JOIN [CovidProject]..CovidVaccinations vaccs ON deaths.location = vaccs.location AND deaths.date = vaccs.date
WHERE deaths.continent is not null
ORDER BY 2,3

-- Using a common table expression (CTE) to perform calculations with newly created rolling_total_vaccinations
WITH PopvsVac (continent, location, date, population, rolling_total_vaccinations)
as 
(
SELECT 
deaths.continent, 
deaths.location, 
deaths.date, 
deaths.population, 
SUM(CONVERT(bigint, vaccs.new_vaccinations)) OVER (PARTITION BY deaths.location ORDER BY deaths.location, deaths.date) as rolling_total_vaccinations
FROM [CovidProject]..CovidDeaths deaths
JOIN [CovidProject]..CovidVaccinations vaccs ON deaths.location = vaccs.location AND deaths.date = vaccs.date
WHERE deaths.continent is not null
)
SELECT *, (rolling_total_vaccinations/population)*100 as percent_vaccinated--Calculate percent of population vaccinated
FROM PopvsVac

-- Same as above but using a TEMP TABLE 
DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
rolling_total_vaccinations numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT 
deaths.continent, 
deaths.location, 
deaths.date, 
deaths.population, 
vaccs.new_vaccinations,
SUM(CONVERT(bigint, vaccs.new_vaccinations)) OVER (PARTITION BY deaths.location ORDER BY deaths.location, deaths.date) as rolling_total_vaccinations
FROM [CovidProject]..CovidDeaths deaths
JOIN [CovidProject]..CovidVaccinations vaccs ON deaths.location = vaccs.location AND deaths.date = vaccs.date
WHERE deaths.continent is not null
ORDER BY 2,3

SELECT *, (rolling_total_vaccinations/population)*100 as percent_vaccinated--Calculate percent of population vaccinated
FROM #PercentPopulationVaccinated

-- GLOBAL NUMBERS

--Death numbers by day
SELECT 
date, 
SUM(new_cases) as total_cases,
SUM(CAST(new_deaths as int)) as total_deaths,
(SUM(CAST(new_deaths as int))/SUM(new_cases))*100 as DeathPercentage
FROM [CovidProject]..CovidDeaths
WHERE continent is not null
GROUP BY date
ORDER BY 1,2

--Total death numbers
SELECT 
SUM(new_cases) as total_cases,
SUM(CAST(new_deaths as int)) as total_deaths,
(SUM(CAST(new_deaths as int))/SUM(new_cases))*100 as DeathPercentage
FROM [CovidProject]..CovidDeaths
WHERE continent is not null
ORDER BY 1,2


-- Creating Views to store data for later visualizations

/*Total Covid Cases and Covid Percentage*/
DROP VIEW IF EXISTS PopulationCovidPercentage

CREATE VIEW PopulationCovidPercentage AS
SELECT 
Location, 
MAX(total_cases) as HighestInfectionCount, 
population,
MAX(CAST(total_cases as INT)/population)*100 as CovidPercentage
FROM [CovidProject]..CovidDeaths
WHERE continent is not null
GROUP BY location, population

SELECT * FROM PopulationCovidPercentage ORDER BY 1

/*Total Deaths and Death Percentage*/
DROP VIEW IF EXISTS PopulationDeathPercentage

CREATE VIEW PopulationDeathPercentage AS
SELECT 
Location, 
MAX(CAST(total_deaths as int)) AS TotalDeathCount,
population,
MAX(CAST(total_deaths as INT)/population)*100 AS TotalDeathPercentage
FROM [CovidProject]..CovidDeaths
WHERE continent is not null 
GROUP BY location, population

SELECT * FROM PopulationDeathPercentage ORDER BY 1

/*Total People Vaccinated and Vaccination Percentage*/
DROP VIEW IF EXISTS PopulationVaccinationPercentage

CREATE VIEW PopulationVaccinationPercentage AS
SELECT 
vaccs.location,
MAX(CAST(vaccs.people_vaccinated as int)) AS people_vaccinated,
deaths.population,
MAX(CAST(vaccs.people_vaccinated as INT)/deaths.population) * 100 as TotalVaccinationPercentage
FROM [CovidProject]..CovidVaccinations vaccs JOIN [CovidProject]..CovidDeaths deaths ON vaccs.location = deaths.location AND vaccs.date = deaths.date
WHERE vaccs.continent is not null
GROUP BY vaccs.location, deaths.population

SELECT * FROM PopulationVaccinationPercentage ORDER BY 1
