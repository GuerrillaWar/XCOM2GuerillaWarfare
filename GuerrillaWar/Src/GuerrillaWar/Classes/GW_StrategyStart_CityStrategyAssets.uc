// This is an Unreal Script
class GW_StrategyStart_CityStrategyAssets extends Object;

static function X2StrategyElementTemplateManager GetMyTemplateManager()
{
	return class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();
}

static function SetUpCityControlZones(XComGameState StartState, optional bool bTutorialEnabled = false)
{
	local XComGameState_WorldRegion RegionState;
	local GW_GameState_CityStrategyAsset CCZ;
	local array<X2StrategyElementTemplate> arrCityTemplates;

	//Picking random cities
	local int MaxCityIterations;
	local int CityIterations;	
	local array<X2CityTemplate> PickCitySet;
	local array<X2CityTemplate> PickedCities;
	local int NumDesired, Index, RandomIndex;
	local Vector2D v2Coords;

	arrCityTemplates = GetMyTemplateManager().GetAllTemplatesOfClass(class'X2CityTemplate');
	MaxCityIterations = 100;

	foreach StartState.IterateByClassType(class'XComGameState_WorldRegion', RegionState)
	{
		PickCitySet.Length = 0;
		for( Index = 0; Index < arrCityTemplates.Length; ++Index )
		{
			v2Coords.x = X2CityTemplate(arrCityTemplates[Index]).Location.x;
			v2Coords.y = X2CityTemplate(arrCityTemplates[Index]).Location.y;

			if(InRegion(RegionState, v2Coords))
			{
				PickCitySet.AddItem(X2CityTemplate(arrCityTemplates[Index]));
			}
		}
		`log("CANDIDATE CITIES: " @ PickCitySet.Length);
		NumDesired = `SYNC_RAND_STATIC(2) + 2;
		CityIterations = 0;
		MaxCityIterations = PickCitySet.Length;
		PickedCities.Length = 0;

		if(PickCitySet.Length > 0)
		{
			do
			{
				RandomIndex = `SYNC_RAND_STATIC(PickCitySet.Length);
				PickedCities.AddItem(PickCitySet[RandomIndex]);
				PickCitySet.Remove(RandomIndex,1);				
				++CityIterations;
			}
			until(PickedCities.Length == NumDesired ||
				  CityIterations == MaxCityIterations );
		}
		`log("PICKED CITIES: " @ PickedCities.Length);
		//Create state objects for the cities, and associate them with the region that contains them
		for( Index = 0; Index < PickedCities.Length; ++Index )
		{
			//Build the state object and add it to the start state
			if (Index == 0)
			{
				CCZ = GW_GameState_CityStrategyAsset(
					class'GW_GameState_StrategyAsset'.static.CreateAssetFromTemplate(StartState, 'StrategyAsset_CityControlZone')
				);
			}
			else
			{
				CCZ = GW_GameState_CityStrategyAsset(
					class'GW_GameState_StrategyAsset'.static.CreateAssetFromTemplate(StartState, 'StrategyAsset_SlumCity')
				);
			}

			CCZ.LoadCityTemplate(PickedCities[Index]);
			CCZ.Region = RegionState.GetReference();
			CCZ.Continent = RegionState.GetContinent().GetReference();

			StartState.AddStateObject(CCZ);
			`log("Added City: " @ CCZ.GetCityDisplayName());

			//Add the city to its region's list of cities
			RegionState.Cities.AddItem( CCZ.GetReference() );
		}	
	}
}

static function bool InRegion(XComGameState_WorldRegion WorldRegion, Vector2D v2Loc)
{
	local X2WorldRegionTemplate RegionTemplate;
	local TRect Bounds;
	local bool bFoundInRegion;

	bFoundInRegion = false;
	RegionTemplate = WorldRegion.GetMyTemplate();
	Bounds = RegionTemplate.Bounds[0];

	if (v2Loc.x > Bounds.fLeft && v2Loc.x < Bounds.fRight &&
	    v2Loc.y > Bounds.fTop && v2Loc.y < Bounds.fBottom)
	{
		bFoundInRegion = true;
	}

	return bFoundInRegion;
}