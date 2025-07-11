# START BACKEND SERVER
```
git clone https://github.com/admin01-afk/ml-backend-docker
cd ml-backend-docker
docker compose up --build
```

# ADD THE MODEL IN LABEL STUDIO
## step 1(project > settings > Model > Connect Model):
![1.png](/home/mehmet/ml-backend-docker/.README-Resources/1.png)
## step 2 (name it, Backend URL: ):
![2.png](/home/mehmet/ml-backend-docker/.README-Resources/2.png)

# important info
* ## datasets location
    #### change - /home/mehmet/datasets:/datasets to - {your local path to data}:/datasets

* ## Labeling Interface:
    ```
    <View>
  <Image name="image" value="$image" zoom="true"/>
  <RectangleLabels name="label" toName="image">
  <Label value="UAV" background="#FFA39E"/></RectangleLabels>
    </View>
    ```

* ## model used for predictions
    ## current model is best_s_v8.pt
    ### to change the model 
    replace the best_s_v8.pt file with new_model.pt  
    change 
    ```
    - ./best_s_v8.pt:/app/best_s_v8.pt
    ```
    with
    ```
    - ./new_model.pt:/app/new_model.pt
    ```
    and in model.py
    change
    ```
    self.model = YOLO("/app/best_s_v8.pt")
    ```
    with
    ```
    self.model = YOLO("/app/new_model.pt")
    ```

    #### also check
    label_studio-ml > api.py