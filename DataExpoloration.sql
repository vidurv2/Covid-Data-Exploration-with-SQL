SELECT * FROM covid.CovidDeaths ORDER BY 3,4;
SELECT * FROM covid.CovidVaccinations ORDER BY 3,4;

-- Change date column to datetime format (need to switch off safe updates)
SET SQL_SAFE_UPDATES=0;
UPDATE covid.CovidVaccinations 
SET date = str_to_date(date,'%d/%m/%y');
UPDATE covid.CovidDeaths 
SET date = str_to_date(date,'%d/%m/%y');
SET SQL_SAFE_UPDATES=1;

SELECT location,date,total_cases,new_cases,total_deaths,population FROM covid.CovidDeaths ORDER BY 1,2;

-- Total Cases vs Total Deaths -calculate death percentage 
SELECT location,date,total_cases,total_deaths,(total_deaths/total_cases)*100 as DeathPercentage
FROM covid.CovidDeaths  WHERE location="India" ORDER BY 1,2;

-- Total Cases vs Population 
SELECT location,date,total_cases,population,(total_cases/population)*100 as PopulationPercentage
FROM covid.CovidDeaths  WHERE location="India" ORDER BY 1,2;

-- Countries with highest infection rate compared to population
SELECT location, MAX(total_cases) as HighestInfectionCount,MAX((total_cases/population))*100 as PopulationPercentage
FROM covid.CovidDeaths WHERE continent IS NOT NULL 
GROUP BY location,population ORDER BY PopulationPercentage DESC;

-- Countries with highest Deaths
-- Unisgned int refers to postiive int ( needed to convert total_deaths from text to int)
SELECT location, MAX(CAST(total_deaths AS UNSIGNED)) as HighestDeathCount
FROM covid.CovidDeaths WHERE continent IS NOT NULL 
GROUP BY location,population ORDER BY HighestDeathCount DESC;

-- Continents with highest deaths 
SELECT continent, MAX(CAST(total_deaths AS UNSIGNED)) as HighestDeathCount
FROM covid.CovidDeaths WHERE continent IS NOT NULL 
GROUP BY continent ORDER BY HighestDeathCount DESC;

-- GLOBAL NUMBERS 
-- Global death percentage each day 
SELECT date,SUM(new_cases) as total_cases, SUM(CAST(new_deaths AS UNSIGNED)) as total_deaths, 
(SUM(CAST(new_deaths AS UNSIGNED))/SUM(new_cases))*100 as DeathPercentage
FROM covid.CovidDeaths WHERE continent IS NOT NULL 
GROUP BY date ORDER BY 1,2 ;

SELECT death.continent,death.location,death.date,death.population,vac.new_vaccinations,
SUM(CAST(vac.new_vaccinations AS UNSIGNED)) 
OVER (PARTITION BY death.location ORDER BY death.location,death.date) as RollingVaccinationCount
FROM covid.CovidDeaths death 
JOIN covid.CovidVaccinations vac ON death.location = vac.location AND death.date = vac.date
WHERE death.continent IS NOT NULL
ORDER BY 2,3;

-- USING Common Table Expressions (CTE) 
WITH PopvsVac ( continent,location,date,population,new_vaccinations,RollingVaccinationCount) AS
(
SELECT death.continent,death.location,death.date,death.population,vac.new_vaccinations,
SUM(CAST(vac.new_vaccinations AS UNSIGNED)) 
OVER (PARTITION BY death.location ORDER BY death.location,death.date) as RollingVaccinationCount
FROM covid.CovidDeaths death 
JOIN covid.CovidVaccinations vac ON death.location = vac.location AND death.date = vac.date
WHERE death.continent IS NOT NULL
)
SELECT *, (RollingVaccinationCount/population)*100 FROM PopvsVac;



-- Using Temp Table 
DROP TABLE IF EXISTS PercentPopulationVaccinated;
CREATE TEMPORARY TABLE PercentPopulationVaccinated (
continent varchar(255), location varchar(255), date date , population double , 
new_vaccinations double , RollingVaccinationCount double
);
INSERT INTO PercentPopulationVaccinated 
SELECT death.continent,death.location,death.date,death.population,vac.new_vaccinations,
SUM(CAST(vac.new_vaccinations AS UNSIGNED)) 
OVER (PARTITION BY death.location ORDER BY death.location,death.date) as RollingVaccinationCount
FROM covid.CovidDeaths death 
JOIN covid.CovidVaccinations vac ON death.location = vac.location AND death.date = vac.date
WHERE death.continent IS NOT NULL ; 

SELECT *, (RollingVaccinationCount/population)*100 FROM PercentPopulationVaccinated;

-- Create view to store data for data visualization later 
CREATE VIEW PercentPilationVaccinated AS 
SELECT death.continent,death.location,death.date,death.population,vac.new_vaccinations,
SUM(CAST(vac.new_vaccinations AS UNSIGNED)) 
OVER (PARTITION BY death.location ORDER BY death.location,death.date) as RollingVaccinationCount
FROM covid.CovidDeaths death 
JOIN covid.CovidVaccinations vac ON death.location = vac.location AND death.date = vac.date
WHERE death.continent IS NOT NULL;

SELECT * FROM PercentPilationVaccinated;




