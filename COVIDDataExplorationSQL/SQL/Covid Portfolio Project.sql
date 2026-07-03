
SELECT *
FROM PortfolioProject..CovidDeaths
ORDER BY 3,4;

SELECT *
FROM PortfolioProject..CovidVaccinations
ORDER BY 3,4;

-- Select Data that is going to be used

SELECT location,date,total_cases,new_cases,total_deaths,population
FROM PortfolioProject..CovidDeaths
ORDER BY 1,2

-- Total Cases Vs Total Deaths
-- Likelihood of Dying if you contract Covid in your country

SELECT location,date,total_cases,total_deaths,(total_deaths/total_cases)*100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE location = '%states'
ORDER BY 2

-- Likelihood of Contracting COVID
-- Percentage of Population that has been reported as COVID Cases
-- Total Cases Vs Population

SELECT 
	location,
	date,
	population,
	total_cases,
	(total_cases/population)*100 AS PercentPopulationInfected
FROM PortfolioProject..CovidDeaths
--WHERE location like '%states'
ORDER BY 1,2


-- Countries with Highest Infection Rate compared to Population
SELECT 
	Location,
	Population,
	MAX(total_cases) AS HighestInfectionCount,
	MAX((total_cases/population)*100) AS PercentPopulationInfected
FROM PortfolioProject..CovidDeaths
--WHERE location ='INDIA'
GROUP BY location,population
ORDER BY PercentPopulationInfected DESC

-- Showing each country's highest total death count
SELECT
	Location,
	MAX(CAST(total_deaths as INT)) AS HighestDeathCount
FROM PortfolioProject..CovidDeaths
where continent is NOT NULL
GROUP BY Location
ORDER BY HighestDeathCount DESC

-- BREAKING THINGS DOWN BY CONTINENT
-- Showing each continent's highest total death count

SELECT
	continent,
	MAX(CAST(total_deaths as INT)) AS HighestDeathCount
FROM PortfolioProject..CovidDeaths
where continent is NOT NULL
GROUP BY continent
ORDER BY HighestDeathCount DESC


-- Global Numbers
-- total COVID cases, total COVID deaths, 
-- and the overall death percentage across all countries in the dataset
SELECT 
	SUM(new_cases) as total_cases,
	SUM(CAST(new_deaths as INT)) as total_deaths,
	SUM(CAST(new_deaths as INT))/SUM(new_cases) * 100 as DeathPercentage
FROM PortfolioProject..CovidDeaths
where continent is NOT NULL


-- Running total (cumulative total) of vaccinations 
-- for each country up to that date.
SELECT 
	dea.continent,
	dea.location,
	dea.date,
	dea.population,
	vac.new_vaccinations,
	SUM(CONVERT(INT,vac.new_vaccinations)) 
	OVER (PARTITION BY dea.location ORDER BY dea.date) AS RollingTotalOfPeopleVaccinated
	--(RollingTotalOfPeopleVaccinated/population)*100
FROM PortfolioProject..CovidDeaths AS dea
JOIN PortfolioProject..CovidVaccinations AS vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3

-- Percentage of the cumulative vaccine doses administered relative to the population.
-- Using CTE to Perform Calculation on Partition By in previous query
WITH PopVsVac (Continent,Location,Date,Population,New_Vaccinations,RollingTotalOfPeopleVaccinated)
AS
(
	SELECT
		dea.continent,
		dea.location,
		dea.date,
		dea.population,
		vac.new_vaccinations,
		SUM(CONVERT(INT,new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.date) AS RollingTotalOfPeopleVaccinated
	FROM PortfolioProject..CovidDeaths dea
	JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
	WHERE dea.continent IS NOT NULL
	
)
SELECT 
	*,(RollingTotalOfPeopleVaccinated/population)*100  AS PercentagePopulationVaccinated
FROM PopVsVac
ORDER BY 2,3

-- USING TEMP TABLE to perform Calculation on Partition By in previous query
DROP TABLE if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(	
	Continent NVARCHAR(255),
	Location NVARCHAR(255),
	Date DATETIME,
	Population NUMERIC,
	New_Vaccinations NUMERIC,
	RollingTotalOfPeopleVaccinated NUMERIC
)

INSERT INTO #PercentPopulationVaccinated
SELECT 
	dea.continent,
	dea.location,dea.date,dea.population,vac.new_vaccinations,
	SUM(CONVERT(INT,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.date) AS RollingTotalOfPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is NOT NULL
ORDER BY dea.location,dea.date

SELECT 
	*,(RollingTotalOfPeopleVaccinated/Population)*100 AS PercentagePopulationVaccinated
FROM #PercentPopulationVaccinated

-- CREATE VIEW TO STORE DATA FOR LATER VISUALIZATIONS

CREATE VIEW PercentPopulationVaccinated AS
SELECT
	dea.continent,dea.location,dea.date,dea.population,vac.new_vaccinations,
	SUM(CONVERT(INT,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.date) AS RollingTotalOfPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL;

SELECT 
	*,(RollingTotalOfPeopleVaccinated/population)*100 AS PercentagePopulationVaccinated
FROM PercentPopulationVaccinated;


