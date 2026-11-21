SET GLOBAL local_infile = 1;
-- GO TO MANAGE CONNECTIONS IN DATABASE AND ADD TO ADVANCE, UNDER OTHERS TAB ===   OPT_LOCAL_INFILE = 1


CREATE TABLE housing_data(
	UniqueID INT,	
	ParcelID VARCHAR(250),
	LandUse	TEXT, 
	PropertyAddress	VARCHAR(250),
	SaleDate	DATE,
	SalePrice	INT, 
	LegalReference	TEXT,
	SoldAsVacant	TEXT,
	OwnerName	TEXT,
	OwnerAddress	VARCHAR(250),
	Acreage	DECIMAL(10,2),
	TaxDistrict	TEXT,
	LandValue	INT,
	BuildingValue	INT,
	TotalValue	INT,
	YearBuilt	DATE,
	Bedrooms	INT,
	FullBath	INT,
	HalfBath	INT
);


LOAD DATA LOCAL INFILE 'C:/Users/USER/Desktop/SQL/PORTFOLIO_PROJECTS/Nashville Housing Data for Data Cleaning (reuploaded).csv'
INTO TABLE housing_data
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES;
    
SELECT *
FROM housing_data;


DROP TABLE housing_data;

-- POPULATE PROPERTY ADDRESS
SELECT *
FROM housing_data
WHERE PropertyAddress = '';   -- FOUND EMPTY  PROP ADDRESS

-- SET EMPTY  PROP ADDRESS TO NULL
UPDATE housing_data
SET PropertyAddress = NULL
WHERE PropertyAddress = '';   

-- COMFIRM UDPATE
SELECT *
FROM housing_data
WHERE PropertyAddress IS NULL; 

-- PARCELID IS LINKED TO PROPERTYADDRESS, USE IT POPULATE NULL EMPTY ADRESS USING ---> IFNULL(IF EMPTY, POPULATE WITH DATA)
SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, IFNULL(a.PropertyAddress, b.PropertyAddress)
FROM housing_data a
JOIN housing_data b
ON a.ParcelID = b.ParcelID
AND a.UniqueID <> b.UniqueID
WHERE a.PropertyAddress IS NULL;

-- JOINED TABLE ON ITSELF AND POPULATED NULL P.ADRESS
UPDATE  housing_data a
JOIN housing_data b
ON a.ParcelID = b.ParcelID
AND a.UniqueID <> b.UniqueID
SET a.PropertyAddress = IFNULL(a.PropertyAddress, b.PropertyAddress)
WHERE a.PropertyAddress IS NULL;

-- SPILTING PROPERTY ADDRESS INTO STREET AND CITY COLUMNS
SELECT 
SUBSTRING_INDEX(PropertyAddress, ',', 1) Address, -- > USE DELIMITER(,) TO SPLIT CHAR 
TRIM(SUBSTRING_INDEX(PropertyAddress, ',', -1))  City  -- > START PICKING TEXT FROM THE LAST (-1) UNTIL THE DELIMITER,
														-- > TRIM REMOVES EMPTY SPACES
FROM housing_data;

-- CREATE NEW COLUMN
ALTER TABLE housing_data
ADD COLUMN PAddress VARCHAR(255) AFTER PropertyAddress,
ADD COLUMN PCity VARCHAR(100) AFTER PAddress;

-- UPDATE TABLE
UPDATE housing_data
SET PAddress = SUBSTRING_INDEX(PropertyAddress, ',', 1),
	PCity = TRIM(SUBSTRING_INDEX(PropertyAddress, ',', -1));

SELECT PropertyAddress, PAddress, PCity
FROM housing_data
LIMIT 50;


-- #########OWNERS ADDRESS
-- CREATE NEW COLUMN
ALTER TABLE housing_data
ADD COLUMN O_StreetAddress VARCHAR(255) AFTER OwnerAddress,
ADD COLUMN O_City VARCHAR(250) AFTER O_StreetAddress,
ADD COLUMN O_State VARCHAR(250) AFTER O_City;

-- SELECT OwnerAddress, SUBSTRING_INDEX(OwnerAddress, ',', 1),
-- 		TRIM(SUBSTRING_INDEX(
-- 			SUBSTRING_INDEX(OwnerAddress, ',', 2),  -- RETRUNS '1XXX XXX, 2XXXX'
--         ',', -1)),
-- 		TRIM(SUBSTRING_INDEX(OwnerAddress, ',', -1))  
-- FROM housing_data;

SELECT *
FROM housing_data;

UPDATE housing_data
SET O_StreetAddress = SUBSTRING_INDEX(OwnerAddress, ',', 1),
	O_City = TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress, ',', 2), ',', -1)),   
    O_State  = SUBSTRING_INDEX(OwnerAddress, ',', -1);

############ ENABLING CONSISTENT DATA IN SOLDAS COLUMN
SELECT DISTINCT(SoldAsVacant)
FROM housing_data
GROUP BY 1;

SELECT SoldAsVacant, 
		CASE WHEN SoldAsVacant = 'N' THEN 'NO'
			 WHEN SoldAsVacant = 'Y' THEN 'YES'
             ELSE SoldAsVacant
             END
FROM housing_data;

UPDATE housing_data
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'N' THEN 'NO'
						WHEN SoldAsVacant = 'No' THEN 'NO'
						WHEN SoldAsVacant = 'Y' THEN 'YES'
						ELSE SoldAsVacant
						END;

WITH num_row_CTE  AS(
SELECT *,
		ROW_NUMBER() OVER (
        PARTITION BY ParcelID,
					 SalePrice,
                     SaleDate,
                     PropertyAddress,
                     LegalReference
                     ORDER BY
							UniqueID)
                            row_num
FROM housing_data
)
DELETE
FROM num_row_CTE
WHERE row_num <> 1;

        
SELECT *
FROM housing_data
;