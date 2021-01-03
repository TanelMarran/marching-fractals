using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CameraMovement : MonoBehaviour
{
    float movementSpeed = 5.0f;
    float mouseSensitivity = 200.0f;
    bool lockView = false;
    float rotationX = 0f;
    float rotationY = 0f;

    private GameObject UI;
    void start()
    {
        Cursor.lockState = CursorLockMode.Locked;
        Cursor.visible = false;
    }

    // Update is called once per frame
    void Update()
    {
        if (Input.GetKey(KeyCode.D))
        {
            transform.Translate(new Vector3(movementSpeed * Time.deltaTime, 0, 0));
        }

        if (Input.GetKey(KeyCode.A))
        {
            transform.Translate(new Vector3(-movementSpeed * Time.deltaTime, 0, 0));
        }

        if (Input.GetKey(KeyCode.W))
        {
            transform.Translate(new Vector3(0, 0, movementSpeed * Time.deltaTime));
        }

        if (Input.GetKey(KeyCode.S))
        {
            transform.Translate(new Vector3(0, 0, -movementSpeed * Time.deltaTime));
        }

        if (Input.GetKey(KeyCode.Space))
        {
            transform.Translate(new Vector3(0, movementSpeed * Time.deltaTime, 0), Space.World);
        }

        if (Input.GetKey(KeyCode.LeftControl))
        {
            transform.Translate(new Vector3(0, -movementSpeed * Time.deltaTime, 0), Space.World);
        }

        if (Input.GetKeyDown(KeyCode.Mouse1))
        {
            changeLockView();
        }

        if (Input.GetKeyDown(KeyCode.Escape))
        {
            Application.Quit();
        }

        if (!lockView)
        {
            float mouseX = Input.GetAxis("Mouse X") * mouseSensitivity * Time.deltaTime;
            float mouseY = Input.GetAxis("Mouse Y") * mouseSensitivity * Time.deltaTime;

            rotationX -= mouseY;
            rotationY += mouseX;
            transform.localRotation = Quaternion.Euler(rotationX, rotationY, 0f);
        }
    }

    void changeLockView()
    {
        lockView = !lockView;

        if (lockView)
        {
            Cursor.lockState = CursorLockMode.None;
            Cursor.visible = true;
        }
        else
        {
            Cursor.lockState = CursorLockMode.Locked;
            Cursor.visible = false;
        }
    }
}