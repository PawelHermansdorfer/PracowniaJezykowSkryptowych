const config = {
    type: Phaser.AUTO,
    scale: {
        mode:       Phaser.Scale.RESIZE,
        autoCenter: Phaser.Scale.CENTER_BOTH
    },
    physics: {
        default: 'arcade',
        arcade: {
            gravity: { y: 1000 },
            debug: false
        }
    },
    backgroundColor: '#00AAAA',
    scene: {
        create: create,
        update: update
    }
};
new Phaser.Game(config);


let level_layout = "0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 \
                    0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 \
                    0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 \
                    0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 \
                    0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 \
                    0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 \
                    0 0 0 0 0 0 0 1 1 1 0 0 0 0 0 0 \
                    X 0 0 0 0 0 0 0 0 0 0 0 0 0 0 M \
                    1 1 1 1 1 1 0 0 0 0 0 1 1 1 1 1 \
"


let player;
let cursors;
let platforms;

let doors;


function
createRect(scene, x, y, w, h, color, group)
{
    const rect = scene.add.rectangle(x, y, w, h, color);
    rect.setOrigin(0, 0);
    scene.physics.add.existing(rect, true);
    rect.body.setSize(w, h);
    rect.body.updateFromGameObject();
    group.add(rect);
    return(rect);
}

function
finish_level()
{
    this.scene.restart();
}


function
load_level(layout)
{
    let dim_x = 0;
    let dim_y = 0;
for (const ch of level_layout)
    {
        if (ch === '0' || ch === '1' || ch === 'X' || ch === 'M')
        {
            currentRow.push(ch);
        }
        else if (ch === '\\')
        {
            if (currentRow.length > 0)
            {
                rows.push(currentRow);
                currentRow = [];
            }
        }
    }
}


////////////////////////////////////////
function
create()
{
    let w = this.scale.width;
    let h = this.scale.height;

    cursors = this.input.keyboard.createCursorKeys();

    // Player
    player = this.add.rectangle(100, 450, 20, 40, 0x0000ff);
    this.physics.add.existing(player);
    player.body.setCollideWorldBounds(true);
    player.body.setDragX(5000);

    // Ground
    platforms = this.physics.add.staticGroup();
    createRect(this, 0, h - 100, 500, 50, 0x00ff00, platforms);
    createRect(this, 700, h - 100, 500, 50, 0x00ff00, platforms);

    this.physics.add.collider(player, platforms);

    // Target
    doors = this.physics.add.staticGroup();
    createRect(this, w-50, h-100-100, 50, 100, 0x020202, doors)

    this.physics.add.overlap(player, doors, finish_level, 0, this);
}


////////////////////////////////////////
function
update()
{
    let x_dir = 0;
    if(cursors.right.isDown)
    {
        x_dir += 1;
    }
    if(cursors.left.isDown)
    {
        x_dir -= 1;
    }

    if(x_dir != 0)
    {
        player.body.setVelocityX(x_dir * 100);
    }
    player.body.setAccelerationX(x_dir * 10000);



    let y_dir = 0
    if(cursors.up.isDown && player.body.touching.down)
    {
        y_dir -= 1
    }
    player.body.setAccelerationY(y_dir * 30000);


    if(player.y > 650)
    {
        this.scene.restart();
    }
}
