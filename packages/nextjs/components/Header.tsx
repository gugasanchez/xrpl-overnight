import React from "react";
import Image from "next/image";
import Link from "next/link";
import { useRouter } from "next/router";

interface HeaderMenuLink {
  label: string;
  href: string;
  icon?: JSX.Element;
}

export const menuLinks: HeaderMenuLink[] = [
  {
    label: "Home",
    href: "/home-screen",
    icon: <Image src="/images/casa.png" alt="Home" width={18} height={18} />,
  },
  {
    label: "My Dashboard",
    href: "/charts",
    icon: <Image src="/images/grafico-simples.png" alt="Dashboard" width={18} height={18} />,
  },
  {
    label: "Logout",
    href: "/",
    icon: <Image src="/images/sair-alt.png" alt="Sair" width={18} height={18} />,
  },
];

export const HeaderMenuLinks = ({ exclude, only }: { exclude?: string; only?: string }) => {
  const router = useRouter();

  return (
    <>
      {menuLinks
        .filter(link => (exclude ? link.label !== exclude : true) && (only ? link.label === only : true))
        .map(({ label, href, icon }) => {
          const isActive = router.pathname === href;
          return (
            <li key={href} className="w-full">
              <Link
                href={href}
                passHref
                className={`block py-2 px-4 text-sm rounded hover:bg-secondary ${isActive ? "bg-secondary" : ""}`}
              >
                <span className="flex items-center gap-2">
                  {icon && React.cloneElement(icon, { style: { height: "120%", marginRight: "8px" } })}
                  {label}
                </span>
              </Link>
            </li>
          );
        })}
    </>
  );
};

export const Header = () => {
  return (
    <div className="fixed top-0 left-0 h-full z-20 shadow-md shadow-secondary bg-base-100" style={{ width: "300px" }}>
      <div className="flex flex-col h-full">
        <Link href="/home-screen" passHref className="flex items-center gap-2 p-4">
          <div className="flex flex-col mt-4">
            <span className="font-semibold text-3xl leading-tight">XRPL Overnight</span>
          </div>
        </Link>
        <ul className="menu menu-vertical px-1 gap-2 flex-grow">
          <HeaderMenuLinks exclude="Logout" only={undefined} />
        </ul>
        <div className="mt-auto mb-4">
          <HeaderMenuLinks only="Logout" exclude={undefined} />
        </div>
      </div>
    </div>
  );
};
