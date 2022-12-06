const router = require("express").Router();
const authorize = require("../middleware/authorize");
const pool = require("../db");
const { popoverClasses } = require("@mui/material");

router.post("/getname", authorize, async (req, res) => {
	try {
		const { type } = req.body;
		let user;
		if (type === "admin") {
			user = await pool.query(
				"SELECT * FROM admin WHERE admin_id = $1;",
				[req.user.id]
			);
			res.json(user.rows[0].admin_name);
		} else if (type === "retailer") {
			user = await pool.query("SELECT * FROM retailer WHERE r_id = $1;", [
				req.user.id,
			]);
			res.json(user.rows[0].r_name);
		} else {
			user = await pool.query("SELECT * FROM customer WHERE c_id = $1;", [
				req.user.id,
			]);
			res.json(user.rows[0].c_username);
		}
	} catch (err) {
		console.error(err.message);
		res.status(500).send("Server error");
	}
});
router.get("/getSender", authorize, async (req, res) => {
	try {
		let getSender = await pool.query("SELECT * from Sender");
		res.json(getSender.rows);
	} catch (err) {
		console.error(err.message);
		res.status(500).send("Server error");
	}
});
router.post("/addInboundExisting", authorize, async (req, res) => {
	try {
		let getSender = await pool.query("SELECT S_NAME from Sender");
		res.json(getSender.rows);
	} catch (err) {
		console.error(err.message);
		res.status(500).send("Server error");
	}
});
router.post("/handleProductApproval", authorize, async (req, res) => {
	try {
		const { name } = req.body;
		let getInventory = await pool.query(
			"SELECT INVENTORY_ID FROM INVENTORY where R_ID = $1 ",
			[req.user.id]
		);

		let checkInventory = await pool.query(
			"SELECT * FROM PRODUCT WHERE INVENTORY_ID = $1 and PRODUCT_NAME = $2",
			[getInventory.rows[0].inventory_id, name]
		);
		if (checkInventory.rows[0]) {
		} else {
			let addID = await pool.query(
				"UPDATE PRODUCT SET INVENTORY_ID = $1 WHERE PRODUCT_NAME=$2",
				[getInventory.rows[0].inventory_id, name]
			);
		}
		let addInventory = await pool.query(
			"UPDATE INVENTORY SET INVENTORY_COUNT = INVENTORY_COUNT+$1",
			[checkInventory.rows[0].PRODUCT_COUNT]
		);
		res.json("success");
	} catch (err) {}
});
router.post("/getRetailerStatus", authorize, async (req, res) => {
	try {
		let user;
		user = await pool.query("SELECT * FROM retailer WHERE r_id = $1;", [
			req.user.id,
		]);
		res.json(user.rows[0].r_approval_status);
	} catch (err) {
		console.error(err.message);
		res.status(500).send("Server error");
	}
});
router.post("/addInventory", authorize, async (req, res) => {
	try {
		const { type, description } = req.body;
		let addretinvent = await pool.query(
			"UPDATE INVENTORY SET inventory_type=$1,inventory_description=$2 WHERE r_id = $3 RETURNING *",
			[type, description, req.user.id]
		);
		let notifDelete = await pool.query(
			"DELETE FROM NOTIFICATIONS WHERE referrer_id=$1",
			[req.user.id]
		);
		res.json("success");
	} catch (err) {
		console.error(err.message);
		res.status(500).send("Server error");
	}
});

router.post("/getProfile", authorize, async (req, res) => {
	try {
		const { type } = req.body;
		let user;
		if (type === "admin") {
			user = await pool.query(
				"SELECT * FROM admin WHERE admin_id = $1;",
				[req.user.id]
			);
			res.json({
				name: user.rows[0].admin_name,
				companyName: "IVMS",
				address: "Karachi, Pakistan",
			});
		} else if (type === "retailer") {
			user = await pool.query("SELECT * FROM retailer WHERE r_id = $1;", [
				req.user.id,
			]);
			res.json({
				name: user.rows[0].r_username,
				companyName: user.rows[0].r_name,
				address: user.rows[0].r_address,
			});
		} else {
			user = await pool.query("SELECT * FROM customer WHERE c_id = $1;", [
				req.user.id,
			]);
			res.json({
				name: user.rows[0].c_username,
				companyName: "",
				address: user.rows[0].c_address,
			});
		}
	} catch (err) {
		res.status(500).send("Server error");
	}
});

router.get("/getInventory", authorize, async (req, res) => {
	try {
		let getID = await pool.query(
			"SELECT * from INVENTORY WHERE R_ID = $1",
			[req.user.id]
		);
		res.json(getID.rows[0]);
	} catch (err) {
		console.error(err.message);
		res.status(500).send("Server error");
	}
});

router.post("/addInboundExisting", authorize, async (req, res) => {
	try {
		const { sendername, count, name } = req.body;
		let getInventory = await pool.query(
			"SELECT INVENTORY_ID FROM INVENTORY WHERE R_ID = $1",
			[req.user.id]
		);
		let s_id = await pool.query(
			"SELECT S_ID FROM SENDER WHERE S_NAME = $1",
			[sendername]
		);
		let addInbound = await pool.query(
			"INSERT INTO INBOUND (PRODUCT_COUNT, PRODUCT_NAME, SENDER_ID, INVENTORY_ID) VALUES ()",
			[name, count, s_id.rows[0].S_ID]
		);
	} catch (err) {
		console.error(err.message);
		res.status(500).send("Server error");
	}
});
router.post("/addInboundNew", authorize, async (req, res) => {
	try {
		const { sendername, count, name, type, description } = req.body;
		let getInventory = await pool.query(
			"SELECT INVENTORY_ID FROM INVENTORY WHERE R_ID = $1",
			[req.user.id]
		);
		console.log("1");

		console.log("2");
		let addInbound = await pool.query(
			"INSERT INTO INBOUND (PRODUCT_COUNT, PRODUCT_NAME, SENDER_ID, INVENTORY_ID) VALUES ($2,$1,$3,$4)",
			[name, count, sendername, getInventory.rows[0].inventory_id]
		);
		console.log("3");
		let addProduct = await pool.query(
			"INSERT INTO PRODUCT (PRODUCT_NAME,PRODUCT_COUNT, PRODUCT_DESCRIPTION, PRODUCT_TYPE) VALUES ($1,$2,$3,$4)",
			[name, count, description, type]
		);
		console.log("4");
		res.json("success");
	} catch (err) {
		console.error(err.message);
		res.status(500).send("Server error");
	}
});
router.post("/getInbound", authorize, async (req, res) => {
	try {
		let { name } = req.body;
		let getInbound;
		if (!name) {
			getInbound = await pool.query(
				"SELECT * FROM INBOUND JOIN INVENTORY ON INBOUND.INVENTORY_ID = INVENTORY.INVENTORY_ID JOIN PRODUCT ON INBOUND.PRODUCT_NAME=PRODUCT.PRODUCT_NAME JOIN SENDER ON SENDER.S_ID=INBOUND.SENDER_ID where R_ID = $1 AND APPROVAL_STATUS=$2",
				[req.user.id, "False"]
			);
		} else {
			getInbound = await pool.query(
				"SELECT * FROM INBOUND JOIN INVENTORY ON INBOUND.INVENTORY_ID = INVENTORY.INVENTORY_ID JOIN SENDER ON SENDER.S_ID=INBOUND.SENDER_ID where R_ID = $1 and INBOUND.product_name LIKE $2 AND APPROVAL_STATUS=$3",
				[req.user.id, "%" + name + "%", "False"]
			);
		}
		res.json(getInbound.rows);
	} catch (err) {
		console.error(err.message);
		res.status(500).send("Server error");
	}
});
router.post("/sendOutbound", authorize, async (req, res) => {
	try {
		const { id, name, count, mobile, address, email } = req.body;
		let getInventory = await pool.query(
			"SELECT INVENTORY_ID FROM INVENTORY WHERE R_ID = $1",
			[req.user.id]
		);
		let addSender = await pool.query(
			"INSERT INTO RECIEVER (S_MOBILE_NUM,S_ADDRESS,S_EMAIL) VALUES ($1,$2,$3) RETURNING *",
			[mobile, address, email]
		);
		let addOutbound = await pool.query(
			"INSERT INTO OUTBOUND (INVENTORY_ID, PRODUCT_ID, PRODUCT_COUNT, PRODUCT_NAME,RECIEVER_ID) VALUES ($1,$2,$3,$4,$5)",
			[getInventory.rows[0], id, count, name, addSender.rows[0].R_ID]
		);
		res.json("success");
	} catch (err) {
		console.error(err.message);
		res.status(500).send("Server error");
	}
});
router.post("/addOutbound", authorize, async (req, res) => {
	try {
		const { count, name, recv_name } = req.body;
		let getInventory = await pool.query(
			"SELECT * FROM INVENTORY WHERE R_ID = $1",
			[req.user.id]
		);
		let getreciever = await pool.query(
			"SELECT R_ID FROM RECIEVER WHERE R_NAME = $1", 
			[recv_name]
		);
		let getProduct = await pool.query(
			"SELECT PRODUCT_ID FROM PRODUCT WHERE PRODUCT_NAME = $1", 
			[name]
		);
		let getOutbound = await pool.query(
			"INSERT INTO OUTBOUND (INVENTORY_ID, PRODUCT_ID, PRODUCT_COUNT,RECIEVER_ID) VALUES ($1,$2,$3,$4)",
			[getInventory.rows[0].inventory_id, getProduct.rows[0],count, getreciever.rows[0]]
		);
		res.json('Success');
	} catch (err) {
		console.error(err.message);
		res.status(500).send("Server error");
	}
});
router.get("/getOutbound", authorize, async (req, res) => {
	try {
		let getOutbound = pool.query(
			"SELECT * FROM OUTBOUND JOIN INVENTORY ON OUTBOUD.INVENTORY_ID = INVENTORY.INVENTORY_ID WHERE R_ID = $1",
			[req.user.id]
		);
		res.json(getOutbound.rows);
	} catch (err) {
		console.error(err.message);
		res.status(500).send("Server error");
	}
});
router.post("/decreaseProduct", authorize, async (req, res) => {
	try {
		const { id, count } = req.body;
		console.log("lmao");
		let getinventory = await pool.query(
			"SELECT INVENTORY_ID from INVENTORY WHERE R_ID = $1",
			[req.user.id]
		);
		let product = await pool.query(
			"SELECT * FROM PRODUCT JOIN INVENTORY ON PRODUCT.INVENTORY_ID = INVENTORY.INVENTORY_ID WHERE INVENTORY.R_ID = $1 AND PRODUCT_ID = $2 ",
			[req.user.id, id]
		);
		let insertion = await pool.query(
			"UPDATE PRODUCT SET PRODUCT_COUNT=$1 WHERE INVENTORY_ID=$2 AND PRODUCT_ID=$3",
			[
				parseInt(product.rows[0].product_count) - parseInt(count),
				getinventory.rows[0].inventory_id,
				id,
			]
		);
		res.json("success");
	} catch (err) {
		console.error(err.message);
		res.status(500).send("Server error");
	}
});
router.post("/addProduct", authorize, async (req, res) => {
	try {
		const { name, count, type, description } = req.body;
		let getinventory = await pool.query(
			"SELECT INVENTORY_ID from INVENTORY WHERE R_ID = $1",
			[req.user.id]
		);

		let product = await pool.query(
			"SELECT * FROM PRODUCT JOIN INVENTORY ON PRODUCT.INVENTORY_ID = INVENTORY.INVENTORY_ID WHERE INVENTORY.R_ID = $1 AND PRODUCT_NAME LIKE $2 ",
			[req.user.id, name]
		);
		if (product.rows[0]) {
			console.log("updation");
			let insertion = await pool.query(
				"UPDATE PRODUCT SET PRODUCT_COUNT=$1 WHERE INVENTORY_ID=$2 AND PRODUCT_NAME=$3",
				[
					parseInt(product.rows[0].product_count) + parseInt(count),
					getinventory.rows[0].inventory_id,
					name,
				]
			);
		} else {
			let addProd = await pool.query(
				"INSERT INTO PRODUCT(INVENTORY_ID, PRODUCT_NAME, PRODUCT_COUNT,PRODUCT_TYPE,PRODUCT_DESCRIPTION) VALUES ($1,$2, $3,$4,$5) RETURNING *",
				[
					getinventory.rows[0].inventory_id,
					name,
					count,
					type,
					description,
				]
			);
			// update the count in inventory
			let updateinvent = await pool.query(
				"UPDATE INVENTORY SET INVENTORY_COUNT = INVENTORY_COUNT+$1 WHERE INVENTORY_ID = $2",
				[count, addProd.rows[0].inventory_id]
			);
		}
		res.json("Success");
	} catch (err) {
		console.error(err.message);
		res.status(500).send("Server error");
	}
});
router.post("/editProduct", authorize, async (req, res) => {
	try {
		const { id, name, count, description, type } = req.body;
		let editProduct = pool.query(
			"UPDATE PRODUCT SET PRODUCT_NAME = $1, PRODUCT_COUNT = $2, PRODUCT_DESCRIPTION = $3, PRODUCT_TYPE = $4 where PRODUCT_ID=$5",
			[name, count, description, type, id]
		);
		res.json("success");
	} catch (err) {
		console.error(err.message);
		res.status(500).send("Server error");
	}
});
router.post("/removeProduct", authorize, async (req, res) => {
	try {
		const { id } = req.body;
		let prod = pool.query("SELECT * FROM PRODUCT WHERE PRODUCT_ID = $1", [
			id,
		]);
		let subtractcount = pool.query(
			"UPDATE INVENTORY SET INVENTORY_COUNT = INVENTORY_COUNT-$1 WHERE INVENTORY_ID = (SELECT INVENTORY_ID from INVENTORY WHERE R_ID = $2)",
			[prod.PRODUCT_COUNT, req.user.id]
		);
		let removeProduct = pool.query(
			"DELETE FROM PRODUCT WHERE PRODUCT_ID = $1",
			[id]
		);
		res.json("success");
	} catch (err) {
		console.error(err.message);
		res.status(500).send("Server error");
	}
});
//search by name of product join product by inventory
router.post("/getProducts", authorize, async (req, res) => {
	try {
		const { name } = req.body;
		let searchProduct = await pool.query(
			"SELECT * FROM PRODUCT JOIN INVENTORY ON PRODUCT.INVENTORY_ID = INVENTORY.INVENTORY_ID WHERE INVENTORY.R_ID = $1 AND PRODUCT_NAME LIKE $2 ",
			[req.user.id, "%" + name + "%"]
		);
		console.log(searchProduct.rows);
		res.json(searchProduct.rows);
	} catch (err) {
		console.error(err.message);
		res.status(500).send("Server error");
	}
});
router.post("/getProductItem", authorize, async (req, res) => {
	try {
		const { id } = req.body;
		let searchProduct = await pool.query(
			"SELECT * FROM PRODUCT WHERE PRODUCT_ID= $1 ",
			[id]
		);
		res.json(searchProduct.rows);
	} catch (err) {
		console.error(err.message);
		res.status(500).send("Server error");
	}
});
router.post("/sendInboundHistory", authorize, async (req, res) => {
	try {
		const { id } = req.body;
		let createHistory = await pool.query(
			"INSERT INTO HISTORY (ID, ENTRY_TIME) VALUES ($1, CURRENT_TIMESTAMP)",
			[id]
		);
	} catch (err) {
		console.error(err.message);
		res.status(500).send("Server error");
	}
});
router.post("/sendOutboundHistory", authorize, async(req,res)=>{
	try {
		const {id} = req.body;
		let createHistory = await pool.query(
			"INSERT INTO HISTORY (ID, ENTRY_TIME) VALUES ($1, CURRENT_TIMESTAMP)",
			[id]
		);
	} catch (err) {
		console.error(err.message);
		res.status(500).send("Server error");
	}
});

module.exports = router;
