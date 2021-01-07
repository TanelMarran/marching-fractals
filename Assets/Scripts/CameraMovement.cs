using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CameraMovement : MonoBehaviour
{
    public float movementSpeed = 5.0f;
    float mouseSensitivity = 200.0f;
    bool lockView = true;
    float rotationX = 0f;
    float rotationY = 0f;

    private Canvas UI;
    private float maxMovementSpeed;

    void Start()
    {
        Cursor.lockState = CursorLockMode.None;
        Cursor.visible = true;
        maxMovementSpeed = movementSpeed;
        
        UI = GameObject.FindWithTag("UI").GetComponent<Canvas>();
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

        if (Input.mouseScrollDelta.y != 0)
        {
            movementSpeed = Mathf.Clamp(movementSpeed + Input.mouseScrollDelta.y * movementSpeed / 2.0f, 0.001f, maxMovementSpeed);
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
            UI.enabled = true;
        }
        else
        {
            Cursor.lockState = CursorLockMode.Locked;
            Cursor.visible = false;
            UI.enabled = false;
        }
    }
}