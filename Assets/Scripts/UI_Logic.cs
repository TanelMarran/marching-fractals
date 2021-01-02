using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.SceneManagement;

public class UI_Logic : MonoBehaviour {

    public void changeScene()
    {
        Scene scene = SceneManager.GetActiveScene();
        string name = scene.name;
        if (name == "MandleBulb")
        {
            SceneManager.LoadScene("Cube");
        } else
        {
            SceneManager.LoadScene("MandleBulb");
        }
    }

    public void randomLightDirection()
    {
        UpdateShader.lightDirection = Vector3.Normalize(Random.insideUnitSphere);
    }

    // Start is called before the first frame update
    void Start()
    {
 
    }

    // Update is called once per frame
    void Update()
    {
        
    }
}
