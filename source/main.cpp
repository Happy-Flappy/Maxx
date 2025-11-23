#include <SFML/Graphics.hpp>
#include <vector>
#include <iostream>
#include <filesystem>
#include <string>
#include <cctype>
#include <fstream>
#include <cmath>

namespace fs = std::filesystem;




float easeInOutCubic(float t) {
    return t < 0.5f ? 4.0f * t * t * t : 1.0f - pow(-2.0f * t + 2.0f, 3.0f) / 2.0f;
}

float easeInCubic(float t) {
    return t * t * t;
}

float easeOutCubic(float t) {
    return 1.0f - pow(1.0f - t, 3.0f);
}

float easeLinear(float t) {
    return t;
}

float applyEasing(float t, const std::string& easingType) {
    if (easingType == "easeInOut") return easeInOutCubic(t);
    if (easingType == "easeIn") return easeInCubic(t);
    if (easingType == "easeOut") return easeOutCubic(t);
    return easeLinear(t);
}




class Layer
{
	public:
	
	std::string name = "";
	std::vector<sf::Image> images;


	void loadLayer(std::string folder)
	{
		std::vector<std::string> paths;
		
		fs::path dir(folder);
	    
	    try {
	        for (const auto& entry : fs::directory_iterator(dir)) {
	            // Check if the entry is a regular file
	            if (fs::is_regular_file(entry.status())) 
				{
					if(entry.path().extension().string() == ".png")
	                {
	                	paths.push_back(entry.path().string());
	            	}
				}
	        }
	        
	        std::sort(paths.begin(), paths.end());//default sort pattern is alphabetically / numerically
	        
	    } catch (const fs::filesystem_error& e) {
	        std::cerr << "Filesystem error: " << e.what() << std::endl;
	    }
	    
	    for(int a=0;a<paths.size();a++)
	    {
	    	sf::Image image;
	    	image.loadFromFile(paths[a]);
	    	images.push_back(image);
		}
		
		
		
		for(int a=0;a<paths.size();a++)
		{
			std::cout << paths[a] << "\n";
		}
		
	}		

};



std::vector<Layer> layers;




std::string digit(int num)
{
	std::string result = "000";
	if(num < 10)
	{
		result = "00" + std::to_string(num);
	}
	if(num >= 10 && num < 100)
	{
		result = "0" + std::to_string(num);
	}
	if(num >= 100)
	{
		result = std::to_string(num);
	}
	return result;
}










class Effect
{
	public:
	
	Effect()
	{
		
	}
	
	std::string type = "none";
	int v1 = 0,v2 = 0,v3 = 0,v4 = 0,v5 = 0;
	int layer = 0;
	std::string easing = "linear";
};



std::vector<Effect> effects;








class Script
{
	public:
	
	
	std::vector<std::string> keys;
	std::string projectPath = "";
	
	
	bool load(std::string path)
	{
		std::ifstream file;
		file.open(path);
		
		if(!file.is_open())
			return false;
		
		std::string key = "";
		while(file >> key)
		{
			keys.push_back(key);
		}
		
		file.close();
		
		
		fs::path projPath(path);
		projectPath = projPath.remove_filename().string();
		
		translate();
		
		return true;
	}
	
	
	
	int toInt(std::string str)
	{
		return std::stoi(str);
	}
	
	
	void translate()
	{
		for(int a=0;a<keys.size();a++)
		{
			if(keys[a] == "Layer")
			{
				Layer newlayer;
				newlayer.name = keys[a+1];
				layers.push_back(newlayer);
				a+=1;
				continue;
			}
			
			for(int v=0;v<layers.size();v++)
			{
				if(keys[a] == layers[v].name) 
				{
					
					
					if(keys[a+1] == "load")
					{
						std::string r = keys[a+2];
						r.erase(r.begin());
						r.erase(r.length()-1);
						
						//local path or full
						
						fs::path pathr = fs::path(r);
						if(pathr.is_absolute())
							layers[v].loadLayer(r);
						else
						{
							//resolve it
							std::string resolve = projectPath + "\\" + r;
							std::cout << "Getting Layer at: ";
							std::cout << resolve << "\n";
							layers[v].loadLayer(resolve);
						}
					}
					
					if(keys[a+1] == "fadeIn")
					{
						int frameStart = toInt(keys[a+2]);
						int frameEnd = toInt(keys[a+3]);
						Effect effect;
						effect.v1 = frameStart;
						effect.v2 = frameEnd;
						effect.type = "fadeIn";
						effect.layer = v;
						effects.push_back(effect);
					}
					
					if(keys[a+1] == "fadeOut")
					{
						int frameStart = toInt(keys[a+2]);
						int frameEnd = toInt(keys[a+3]);
						Effect effect;
						effect.v1 = frameStart;
						effect.v2 = frameEnd;
						effect.type = "fadeOut";
						effect.layer = v;
						effects.push_back(effect);					
					}
					
					
					
					if(keys[a+1] == "zoomIn")
					{
						int frameStart = toInt(keys[a+2]);
						int frameEnd = toInt(keys[a+3]);
						int focusX = toInt(keys[a+4]);
						int focusY = toInt(keys[a+5]);
						int zoomSpeed = toInt(keys[a+6]);
						Effect effect;
						effect.v1 = frameStart;
						effect.v2 = frameEnd;
						effect.v3 = focusX;
						effect.v4 = focusY;
						effect.v5 = zoomSpeed;
						effect.type = "zoomIn";
						effect.layer = v;
						
						if(a+7 < keys.size() && (keys[a+7] == "easeIn" || keys[a+7] == "easeOut" || keys[a+7] == "easeInOut" || keys[a+7] == "linear"))
						{
							effect.easing = keys[a+7];
						}						
						
						
						effects.push_back(effect);						
					}
					
					if(keys[a+1] == "zoomOut")
					{
						int frameStart = toInt(keys[a+2]);
						int frameEnd = toInt(keys[a+3]);
						int focusX = toInt(keys[a+4]);
						int focusY = toInt(keys[a+5]);
						int zoomSpeed = toInt(keys[a+6]);
						Effect effect;
						effect.v1 = frameStart;
						effect.v2 = frameEnd;
						effect.v3 = focusX;
						effect.v4 = focusY;
						effect.v5 = zoomSpeed;
						effect.type = "zoomOut";
						effect.layer = v;

						if(a+7 < keys.size() && (keys[a+7] == "easeIn" || keys[a+7] == "easeOut" || keys[a+7] == "easeInOut" || keys[a+7] == "linear"))
						{
							effect.easing = keys[a+7];
						}						


						effects.push_back(effect);				
					}
					
					
					if(keys[a+1] == "reset")
					{
						int q = toInt(keys[a+2]);
						Effect effect;
						effect.v1 = q;
						effect.type = "reset";
						effect.layer = v;
						effects.push_back(effect);						
					}
					
					
					break;
				}
			}
		}
	}
	
		
};












int main(int argc, char *argv[])
{
	sf::RenderWindow window(sf::VideoMode(960,540),"");


	Script script;
	
	std::string project = "";
	
	if(argc == 2)
	{
		project = argv[1];
	}
	
	
	if(project == "")
	{
		std::cout << "Project Path:";
		std::cin >> project;
	}
	
	while(!script.load(project))
	{
		std::cout << "Failed to Load Project!\n";
		std::cout << "Project Path:";
		std::cin >> project;
	}	
	
	
	
	
	
	int currentFrame = 0;
	bool save = false;
	
	sf::RenderTexture canvas;
	canvas.create(960,540);
	
	
	sf::View view;
	view.reset(sf::FloatRect(0,0,960,540));
	
	
	while(window.isOpen())
	{
		sf::Event event;
		while(window.pollEvent(event))
		{
			if(event.type == sf::Event::Closed)
				window.close();
				
			if(event.type == sf::Event::KeyPressed)
			{
				if(!save)
				{
					if(event.key.code == sf::Keyboard::Left)
						currentFrame --;
					if(event.key.code == sf::Keyboard::Right)
						currentFrame ++;
				}
				if(event.key.code == sf::Keyboard::S)
				{
					save = true;
					currentFrame = 0;
				}	
			}	
		}
		
		
		
		window.clear(sf::Color::White);
		
	
		
		canvas.setView(view);
		canvas.clear(sf::Color::Transparent);
		
		for(int a=0;a<layers.size();a++)
		{
			if(currentFrame < 0 || currentFrame >= layers[a].images.size())
				continue;
			
			sf::Sprite sprite;
			sf::Texture texture;
			texture.loadFromImage(layers[a].images[currentFrame]);
			sprite.setTexture(texture);
			
			
			sprite.setColor(sf::Color::White);
			
			

			for(int b=0;b<effects.size();b++)
			{
				
				
				if(effects[b].layer != a)
					continue;
									
				if(currentFrame < effects[b].v1 || currentFrame > effects[b].v2)
					continue;
			
				if(effects[b].type == "fadeOut")
				{
				    int totalFrames = effects[b].v2 - effects[b].v1;
				    int currentFrameInEffect = currentFrame - effects[b].v1;
				    int fade = 255 - (255 * currentFrameInEffect / totalFrames);
				    sprite.setColor(sf::Color(255,255,255,fade));
					
				}
				
				if(effects[b].type == "fadeIn")
				{
				    int totalFrames = effects[b].v2 - effects[b].v1;
				    int currentFrameInEffect = currentFrame - effects[b].v1;
				    int fade = 255 * currentFrameInEffect / totalFrames;
				    sprite.setColor(sf::Color(255,255,255,fade));
				}	
				
				if(effects[b].type == "zoomIn")
				{
				    int totalFrames = effects[b].v2 - effects[b].v1;
				    int currentFrameInEffect = currentFrame - effects[b].v1;
				    float progress = static_cast<float>(currentFrameInEffect) / totalFrames;
				    
				    progress = applyEasing(progress, effects[b].easing);
				    
				    float zoomFactor = 1.0f + (progress * effects[b].v5 / 10); // Start from 1.0 and increase
				    
				    // Set origin to the focus point (relative to sprite texture size)
				    // First get the texture size to calculate proper origin coordinates
				    sf::Vector2u textureSize = sprite.getTexture()->getSize();
				    float originX = (effects[b].v3 / 960.0f) * textureSize.x; // Convert from screen coords to texture coords
				    float originY = (effects[b].v4 / 540.0f) * textureSize.y;
				    
				    sprite.setOrigin(originX, originY);
				    
				    sprite.setScale(zoomFactor, zoomFactor);
				    
				    std::cout<<zoomFactor<<"\n";
				    
				    // Position the sprite so the origin point matches the desired screen position
				    sprite.setPosition(effects[b].v3, effects[b].v4);
				    
				    
				}

				if(effects[b].type == "zoomOut")
				{
				    int totalFrames = effects[b].v2 - effects[b].v1;
				    int currentFrameInEffect = currentFrame - effects[b].v1;
				    float progress = static_cast<float>(currentFrameInEffect) / totalFrames;
				    
				    progress = applyEasing(progress, effects[b].easing);
				    
				    // Start from a larger zoom factor and decrease to 1.0
				    float zoomFactor = 1.0f + ((1.0f - progress) * effects[b].v5 / 10);
				    
				    // Set origin to the focus point (relative to sprite texture size)
				    sf::Vector2u textureSize = sprite.getTexture()->getSize();
				    float originX = (effects[b].v3 / 960.0f) * textureSize.x;
				    float originY = (effects[b].v4 / 540.0f) * textureSize.y;
				    
				    sprite.setOrigin(originX, originY);
				    sprite.setScale(zoomFactor, zoomFactor);
				    
				    std::cout << "Zoom Out Factor: " << zoomFactor << "\n";
				    
				    // Position the sprite so the origin point matches the desired screen position
				    sprite.setPosition(effects[b].v3, effects[b].v4);
				}
				
			}
			
			canvas.draw(sprite);
			
		}
		
		
		canvas.display();
		
		sf::Sprite spr;
		spr.setTexture(canvas.getTexture());
		spr.setOrigin(canvas.getSize().x/2,canvas.getSize().y/2);
		spr.setPosition(window.getView().getCenter());
		spr.setScale(1,1);
		
		window.draw(spr);
		
		window.display();
		
		
		
		if(save)
		{
			std::string savepath = script.projectPath + "/output";
			
			std::filesystem::create_directory(savepath);
			
			
			if(!std::filesystem::exists(savepath))
			{
				std::cout << "Error! Failed to Create output directory for project! You might want to check if your project is accessible.\n";
				save = false;
				
			}
			
			
			if(save)
			{
			
				canvas.getTexture().copyToImage().saveToFile(savepath + digit(currentFrame) + ".bmp");
				currentFrame++;
				
				std::cout << "Finished saving "+ digit(currentFrame) + ".bmp\n";
				
				int maximum = 0;
				for(int a=0;a<layers.size();a++)
				{
					if(layers[a].images.size() > maximum)
						maximum = layers[a].images.size();
				}
				
				if(currentFrame > maximum)
				{
					std::cout << "Finished saving to file!\n";
					return 0;
				}
			}
		}
		
	}
}